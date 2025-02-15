Class {
	#name : #SoilIndexManager,
	#superclass : #Object,
	#instVars : [
		'segment',
		'indexes',
		'semaphore'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #accessing }
SoilIndexManager class >> indexClassFromFile: aFileReference [ 
	| stream pageCode headerPage |
	stream := aFileReference binaryReadStream.
	pageCode := stream next.
	stream close.
	headerPage :={ SoilSkipListHeaderPage . SoilBTreeHeaderPage } detect: [ :each | each pageCode = pageCode ].
	^ headerPage indexClass
]

{ #category : #visiting }
SoilIndexManager >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitIndexManager: self 
]

{ #category : #accessing }
SoilIndexManager >> at: indexId ifAbsent: aBlock [ 
	^ semaphore critical: [  
		indexes 
			at: indexId 
			ifAbsentPut: [ 
				self 
					loadIndexWithId: indexId 
					ifNone: aBlock  ] ]
		
]

{ #category : #accessing }
SoilIndexManager >> at: indexId put: aSoilIndex [
	^ semaphore critical: [  
		indexes 
			at: indexId
			put: aSoilIndex thePersistentInstance ]
]

{ #category : #'open/close' }
SoilIndexManager >> close [
	semaphore critical: [  
		indexes valuesDo: #close ]
]

{ #category : #api }
SoilIndexManager >> createIndexWithId: indexId class: aClass [ 
	^ aClass new 
		path: (self pathFor: indexId);
		initializeFilesystem;
		initializeHeaderPage
]

{ #category : #accessing }
SoilIndexManager >> flush [
	self indexes do: #flush
]

{ #category : #flushing }
SoilIndexManager >> flushIndexes [
	indexes do: #flushCachedPages
]

{ #category : #accessing }
SoilIndexManager >> indexes [

	^ indexes
]

{ #category : #initialization }
SoilIndexManager >> initialize [ 
	super initialize.
	indexes := Dictionary new.
	semaphore := Semaphore forMutualExclusion 
]

{ #category : #initialization }
SoilIndexManager >> initializeFilesystem [
	self path ensureCreateDirectory 
]

{ #category : #api }
SoilIndexManager >> loadIndexWithId: indexId ifNone: aBlock [
	| path |
	path := self path / indexId , #index.
	^ path exists
		ifTrue: [ 
			(self class indexClassFromFile: path) new 
				path: path;
				open ]
		ifFalse: [ aBlock value ]
]

{ #category : #'open/close' }
SoilIndexManager >> open [
	
]

{ #category : #accessing }
SoilIndexManager >> path [ 
	^ segment path / #indexes
]

{ #category : #accessing }
SoilIndexManager >> pathFor: indexId [ 
	^ self path / indexId , #index
]

{ #category : #accessing }
SoilIndexManager >> segment [
	^ segment
]

{ #category : #accessing }
SoilIndexManager >> segment: aSOObjectSegment [ 
	segment := aSOObjectSegment 
]
