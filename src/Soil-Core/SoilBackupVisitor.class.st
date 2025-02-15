Class {
	#name : #SoilBackupVisitor,
	#superclass : #SoilVisitor,
	#instVars : [
		'source',
		'target',
		'seen',
		'toBeProcessed'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #api }
SoilBackupVisitor >> backup: aSoil [ 
	| objectId |
	source := aSoil.
	self visit: source.
	
	[ toBeProcessed isEmpty ] whileFalse: [  
		objectId := toBeProcessed  removeFirst.
		self visit: (source objectRepository at: objectId) ].
	target close
]

{ #category : #visiting }
SoilBackupVisitor >> copyIndexAt: indexId segment: segmentId [
	| sourceSegment sourceIndex targetSegment targetIndex iterator assoc |
	
	sourceSegment := source objectRepository segmentAt: segmentId.
	sourceIndex := sourceSegment indexManager 
		loadIndexWithId: indexId 
		ifNone: [ Error signal: 'cannot find index with id ', indexId printString ].
	
	"create an index of same kind and configuration in the target database"
	targetSegment := target objectRepository segmentAt: segmentId.
	targetIndex := targetSegment indexManager 
		createIndexWithId: indexId 
		class: sourceIndex class.
	targetIndex initializeParametersFrom: sourceIndex. 
	
	"copy all values to the new index"
	iterator := sourceIndex newIterator.
	[ (assoc := iterator nextAssociation) isNil  ] whileFalse: [  
		"only copy keys that have a value that is not removed"
		assoc value isRemoved ifFalse: [ 
			targetIndex basicAt: assoc key put: assoc value.
			"recurse further into the values of the index"
			self process: assoc value ] ].
	targetIndex
		flush; 
		close.
]

{ #category : #initialization }
SoilBackupVisitor >> initialize [ 
	super initialize.
	seen := Set new.
	toBeProcessed := OrderedCollection new
]

{ #category : #accessing }
SoilBackupVisitor >> process: aSoilObjectId [ 
	"don't continue if the objectId is the behavior description meta object"
	((aSoilObjectId segment = 0) and: [ aSoilObjectId index = 2 ]) ifTrue: [ ^ self ].
	(seen includes: aSoilObjectId) ifTrue: [ ^ self ].
	seen add: aSoilObjectId.
	toBeProcessed add: aSoilObjectId  
]

{ #category : #accessing }
SoilBackupVisitor >> target: aSoil [ 
	target := aSoil
]

{ #category : #visiting }
SoilBackupVisitor >> visitMetaSegment: aSoilMetaSegment [ 
	self visit: aSoilMetaSegment indexManager.
	self copyIndexAt: #identifier segment: 0. 
	^ aSoilMetaSegment  
]

{ #category : #visiting }
SoilBackupVisitor >> visitObjectSegment: aSoilObjectSegment [ 
	self process: SoilObjectId root.
	super visitObjectSegment: aSoilObjectSegment.
]

{ #category : #visiting }
SoilBackupVisitor >> visitParameters: aSoilParameterFile [ 
	target settings 
		databaseFormatVersion: aSoilParameterFile databaseFormatVersion;
		databaseVersion: aSoilParameterFile databaseVersion;
		applicationVersion: aSoilParameterFile applicationVersion
]

{ #category : #visiting }
SoilBackupVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	| backupCluster |
	backupCluster := aSoilPersistentClusterVersion copy
		behaviorDescriptions: aSoilPersistentClusterVersion behaviorDescriptions;
		references: aSoilPersistentClusterVersion references;
		bytes: aSoilPersistentClusterVersion bytes;
		version: aSoilPersistentClusterVersion version;
		resetPreviousVersion.
	target objectRepository 
		at: backupCluster objectId
		put: backupCluster serialize.
	backupCluster references do: [ :reference |
		self process: reference ].
	aSoilPersistentClusterVersion indexIds do:[ :indexId |
		self copyIndexAt: indexId segment: aSoilPersistentClusterVersion segment ].

	^ aSoilPersistentClusterVersion 
]
