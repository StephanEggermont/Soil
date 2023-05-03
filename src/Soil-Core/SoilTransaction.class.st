Class {
	#name : #SoilTransaction,
	#superclass : #Object,
	#instVars : [
		'soil',
		'idMap',
		'objectMap',
		'recordsToCommit',
		'readVersion',
		'writeVersion',
		'behaviorDescriptions',
		'locks',
		'lastObjectIndexes',
		'journal',
		'indexes'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #aborting }
SoilTransaction >> abort [
	recordsToCommit := nil.
	behaviorDescriptions := nil.
	soil := nil.
	idMap := nil.
	objectMap := nil
]

{ #category : #accessing }
SoilTransaction >> acquireLocksAndDetectWriteSkew [
	lastObjectIndexes := Dictionary new.
	"first iterate over all records to acquire locks and check for concurrent 
	writes. Might be changed later to rely on the journal in case of accident"
	recordsToCommit do: [ :record |
		record initializeObjectIdsIn: self.
		"check if the version we've read is still actual. Another transaction could have
		committed since we last read. Checking for the position in the index is sufficient
		as each version relates to a unique position"
		locks add: record lockIndex.
		record validateReadVersion ]
]

{ #category : #adding }
SoilTransaction >> addClusterObject: anObject [ 
	| objectId |
	objectMap at: anObject ifPresent: [ :record |  ^ record objectId ].
	objectId := self newObjectId .
	self 
		atObjectId: objectId
		putObject: anObject.
	^ objectId

]

{ #category : #'as yet unclassified' }
SoilTransaction >> allocateObjectId: aSOObjectId [ 
	aSOObjectId initializeIndex: self objectRepository 
]

{ #category : #accessing }
SoilTransaction >> atObjectId: objectId putObject: anObject [
	| record |
	record := SoilNewClusterVersion new
		object: anObject;
		objectId: objectId;
		transaction: self.
	idMap at: objectId put: record.
	objectMap at: anObject put: record.
	recordsToCommit ifNotNil: [ recordsToCommit add: record ]
]

{ #category : #public }
SoilTransaction >> behaviorDescriptionFor: aClass [
	| behaviorDescription objectId |
	"locally created behavior descriptions are always current and can
	be returned immediately"
	behaviorDescriptions
		at: aClass soilBehaviorIdentifier
		ifPresent: [ :description | ^ description ].
	"if we find the behaviorIdentifier in the registry and it is 
	current we can return it"
	objectId := soil behaviorRegistry
		nameAt: aClass soilBehaviorIdentifier
		ifAbsent: [ nil ].
		
	objectId ifNotNil: [ 
		behaviorDescription := (objectId index = 2)
			ifTrue: [ ^ SoilBehaviorDescription meta ]
			ifFalse: [ (self objectWithId: objectId) objectId: objectId].
		"the description in the database might not be current, if not, we create a new one later"
		behaviorDescription isCurrent 
			ifTrue: [ ^ behaviorDescription ] ].
			
	"behaviorDescription is only set if we've found an old version"
	behaviorDescription 
		ifNotNil: [ 
			"modify existing description and increment version"
			behaviorDescription 
				initializeFromBehavior: aClass;
				incrementVersion.
			"add a new version record to keep the previous position"
			self makeNewVersion: behaviorDescription  ]
		ifNil: [  
			"this is a new description with version 1"
			behaviorDescription := (SoilBehaviorDescription for: aClass)
				beFirstVersion;
				objectId: self newMetaObjectId.
			behaviorDescription objectId initializeIndex: self objectRepository.
			self atObjectId: behaviorDescription objectId putObject: behaviorDescription. ].
	
	behaviorDescriptions
		at: aClass soilBehaviorIdentifier
		put: behaviorDescription.
	^ behaviorDescription
]

{ #category : #'as yet unclassified' }
SoilTransaction >> behaviorDescriptionWithIndex: index andVersion: version [ 
	
	idMap 
		detect: [ :each | each objectId = index ]
		ifFound: [ :record | 
			(record object version = version)
				ifTrue: [ ^ record object ] ].

	^ self behaviorRegistry behaviorDescriptionWithIndex: index andVersion: version transaction: self
]

{ #category : #accessing }
SoilTransaction >> behaviorRegistry [
	^ soil behaviorRegistry 
]

{ #category : #'as yet unclassified' }
SoilTransaction >> behaviorVersionsUpTo: aSOBehaviorDescription [ 
	^ self behaviorRegistry 
		behaviorVersionsUpTo: aSOBehaviorDescription
		transaction: self .
	
]

{ #category : #accessing }
SoilTransaction >> buildJournal [
	journal := SoilJournal new
		transaction: self;
		create.
	recordsToCommit do: [ :record | 
		record version: writeVersion.
		journal addEntries: record asJournalEntry.
		record committed  ].
	^ journal
]

{ #category : #accessing }
SoilTransaction >> buildWriteVersion [
	^ soil databaseVersion + 1 
]

{ #category : #accessing }
SoilTransaction >> checkpoint [
	"serialize objects and collect all to be written records. This can be done without 
	resources that need locking. This reduces time needed for locking"
	self prepareRecordsForCommit.
	"only one transactions is allowed at a time. We use the critical block of the database
	to avoid parallel committing"
	soil critical: [ 
	"enter lock phase. Acquire lock on global databaseVersion which centrally locks
	the database for commiting until this checkpoint is done. The ensure block is needed
	to be sure to release all locks at the end."
		[ 
		locks add: (soil lockDatabaseVersionFor: self).
		"Now the version is locked. We can read it again to have the real version and
		increment"
		writeVersion := self buildWriteVersion.
		"lock all records in the segment and check indexes for out of date versions"
		self acquireLocksAndDetectWriteSkew.
		"convert the records into journal entries, write the journal to disk and then
		execute the journal on the database"
		"lastObjectIndex contains all version number updates, so these are the segments
		that will be written so we lock all of the segments heap files for appending"
		lastObjectIndexes keys do: [ :segment |
			locks add: (segment lockAppendingFor: self) ].
		self buildJournal
			write;
			commit;
			close.
		indexes values do: #flush.
		"write back the accumulated new indexes for all segments"
		lastObjectIndexes keysAndValuesDo: [ :segment :index |
			segment lastObjectIndex: index value ].
		
		behaviorDescriptions do: [ :description |
			soil behaviorRegistry 
				nameAt: description value behaviorIdentifier 
				put: description objectId ].
		soil behaviorRegistry flush.
		soil databaseVersion: writeVersion ]
				ensure: [self releaseLocks ] ]

]

{ #category : #'as yet unclassified' }
SoilTransaction >> checkpointAndContinue [
	self 
		checkpoint;
		continue
]

{ #category : #accessing }
SoilTransaction >> commit [
	self 
		checkpoint;
		abort
]

{ #category : #actions }
SoilTransaction >> continue [
	recordsToCommit do: [ :record | | persistentRecord |
		persistentRecord := record asPersistentClusterVersion.
		objectMap at: record object put: persistentRecord.
		idMap at: record objectId put: persistentRecord ].
	recordsToCommit := nil.
	readVersion := writeVersion.
	writeVersion := nil.
	journal := nil
]

{ #category : #aborting }
SoilTransaction >> dirtyObjects [
	^ (idMap select: [ :each | each hasChanged ]) collect: #object
]

{ #category : #testing }
SoilTransaction >> hasModifications [ 
	^ self dirtyObjects notEmpty
]

{ #category : #'as yet unclassified' }
SoilTransaction >> idOf: anObject [ 
	| id |
	id := objectMap at: anObject.
	(id index = 0) ifTrue: [ Error signal: 'index of object id is not initialized' ].
	^ id
]

{ #category : #accessing }
SoilTransaction >> indexAt: anObject ifAbsent: aBlock [ 
	^ indexes
		at: anObject
		ifAbsentPut: [ 
			self lookupIndex: anObject ifNone: aBlock ]
]

{ #category : #accessing }
SoilTransaction >> indexes [ 
	^ indexes
]

{ #category : #initialization }
SoilTransaction >> initialize [ 
	super initialize.
	idMap := IdentityDictionary new.
	objectMap := IdentityDictionary new.
	behaviorDescriptions := Dictionary new.
	locks := OrderedCollection new.
	indexes := IdentityDictionary new
]

{ #category : #'as yet unclassified' }
SoilTransaction >> initializeObjectId: anObjectId [
	| segment assoc |
	anObjectId isInitialized ifTrue: [ SoilObjectIdAlreadyInitialized signal: 'object id is already initialized: ', anObjectId asString ].
	segment := self objectRepository segmentAt: anObjectId segment.
	"maintain last object indexes per segment"
	assoc := lastObjectIndexes 
		at: segment 
		ifAbsentPut: [ 
			locks add: (segment lockLastObjectIndexFor: self).
			segment lastObjectIndex -> segment lastObjectIndex ].
	"we use an association here to keep the version read from database
	as well as the new version"
	assoc value: assoc value + 1.
	anObjectId index: assoc value
]

{ #category : #testing }
SoilTransaction >> isAborted [
	^ soil isNil and:[ idMap isNil and: [objectMap isNil]]
]

{ #category : #testing }
SoilTransaction >> isChanged [
	^ self hasModifications 
]

{ #category : #testing }
SoilTransaction >> isPersistent: anObject [
	^ self isRoot: anObject
]

{ #category : #testing }
SoilTransaction >> isRoot: anObject [
	self flag: #todo.
	"this is surely not true but a shortcut for now"
	^ (objectMap 
		at: anObject theNonSoilProxy 
		ifAbsent: [ nil ]) notNil
]

{ #category : #'as yet unclassified' }
SoilTransaction >> lockObjectId: aSOObjectId [ 
	^ self objectRepository lockObjectId: aSOObjectId for: self
]

{ #category : #'as yet unclassified' }
SoilTransaction >> lookupIndex: anObject ifNone: aBlock [
	| objectId segment |
	objectId := (objectMap at: anObject) objectId.
	segment := self objectRepository segmentAt: objectId segment.
	^ segment indexAt: anObject ifAbsent: aBlock
]

{ #category : #public }
SoilTransaction >> makeNewVersion: classDescription [
	| record |
	record := objectMap at: classDescription.
	recordsToCommit 
		add: record asNewClusterVersion
]

{ #category : #'as yet unclassified' }
SoilTransaction >> makePersistent: anObject [ 
	self makeRoot: anObject 
]

{ #category : #'as yet unclassified' }
SoilTransaction >> makeRoot: anObject [ 
	| objectId |
	objectId := self addClusterObject: anObject theNonSoilProxy.
	anObject soilClusterRootIn: self.
	^ objectId

]

{ #category : #public }
SoilTransaction >> markDirty: anObject [
	| record |
	"look up the non-proxy object in the local cache"
	record := objectMap 
		at: anObject theNonSoilProxy
		ifAbsent: [ SoilNotAClusterRoot signal: 'cannot mark dirty a non-existing root' ].
	record beChanged. 
	
]

{ #category : #'as yet unclassified' }
SoilTransaction >> materializationWithId: objectId [
	| record |
	record := (self objectRepository at: objectId version: readVersion)
		transaction: self;
		materializeObject. 
	idMap at: objectId put: record.
	objectMap at: record object put: record.
	^ record object
]

{ #category : #'instance creation' }
SoilTransaction >> newClusterVersion [
	^ SoilNewClusterVersion new
		changed: true; 
		transaction: self.
]

{ #category : #'instance creation' }
SoilTransaction >> newMaterializer [
	^ soil newMaterializer 
		transaction: self;
		yourself
]

{ #category : #'instance creation' }
SoilTransaction >> newMetaObjectId [
	^ self objectRepository newMetaObjectId
]

{ #category : #'instance creation' }
SoilTransaction >> newObjectId [ 
	^ self objectRepository newObjectId
]

{ #category : #'instance creation' }
SoilTransaction >> newPersistentClusterVersion [
	^ SoilPersistentClusterVersion new
		transaction: self.
]

{ #category : #accessing }
SoilTransaction >> newSerializer [
	^ soil newSerializer
		transaction: self;
		yourself

]

{ #category : #accessing }
SoilTransaction >> objectIndex [
	^ objectMap
]

{ #category : #'as yet unclassified' }
SoilTransaction >> objectRepository [ 
	^ soil objectRepository
]

{ #category : #'as yet unclassified' }
SoilTransaction >> objectWithId: objectId [
	idMap 
		detect: [ :each | each objectId = objectId ]
		ifFound: [ :record | ^ record object ].

	^ (self materializationWithId: objectId)
		soilLoadedIn: self;
		yourself
]

{ #category : #accessing }
SoilTransaction >> prepareRecordsForCommit [.
	"select all dirty/new records and convert them to new version records"
	recordsToCommit := idMap values asOrderedCollection 
		select: [:each | each value shouldBeCommitted ]
			thenCollect: [:each | each asNewClusterVersion ].
	"serialize initial records. While serializing there can be new records 
	popping up (an object not registered yet in the transaction but is a
	cluster root"
	self serializeObjects.
	"now the list of records to write is complete"

]

{ #category : #printing }
SoilTransaction >> printOn: aStream [ 
	aStream << 'transaction read: ' << readVersion asString << ', write: ' << writeVersion asString
]

{ #category : #'as yet unclassified' }
SoilTransaction >> proxyForObjectId: aSOObjectId [ 
	^ aSOObjectId asSoilObjectProxy 
		transaction: self
]

{ #category : #accessing }
SoilTransaction >> readVersion: anInteger [ 
	readVersion := anInteger
]

{ #category : #accessing }
SoilTransaction >> records [
	^ idMap values
]

{ #category : #'as yet unclassified' }
SoilTransaction >> registerIndexedObject: anObject forRoot: aClusterRoot [
	| objectId segment |
	indexes at: anObject ifPresent: [ Error signal: 'shouldnt happen' ].
	objectId := (objectMap at: aClusterRoot) objectId.
	segment := self objectRepository segmentAt: objectId segment.
	^ indexes 
		at: anObject 
		put: (segment registerIndexedObject: anObject)
]

{ #category : #'as yet unclassified' }
SoilTransaction >> releaseLocks [
	locks do: [ :lock | lock release ].
	locks := OrderedCollection new
]

{ #category : #accessing }
SoilTransaction >> root [

	^ self objectWithId: SoilObjectId root
]

{ #category : #accessing }
SoilTransaction >> root: anObject [
	self 
		atObjectId: SoilObjectId root 
		putObject: anObject.
	anObject soilClusterRootIn: self
]

{ #category : #accessing }
SoilTransaction >> serializeObjects [
	| index |
	index := 1.
	"process the loop in a way new records that appear while serializing
	are taken into account"
	[ index <= recordsToCommit size ] whileTrue: [ 
		(recordsToCommit at: index) serializeObject.
		index := index + 1 ]
]

{ #category : #accessing }
SoilTransaction >> soil [
	^ soil
]

{ #category : #accessing }
SoilTransaction >> soil: aSoil [ 
	soil := aSoil
]

{ #category : #accessing }
SoilTransaction >> writeVersion [
	^ writeVersion
]