Class {
	#name : #SoilIndexPage,
	#superclass : #Object,
	#instVars : [
		'index',
		'dirty',
		'pageSize'
	],
	#classInstVars : [
		'random'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #accessing }
SoilIndexPage class >> pageCode [ 
	self subclassResponsibility 
]

{ #category : #accessing }
SoilIndexPage class >> random [
	^ random ifNil: [ 
		random := Random seed: Time microsecondClockValue. ]
]

{ #category : #'instance creation' }
SoilIndexPage class >> readPageFrom: aStream keySize: keySize valueSize: valueSize [
	| pageCode pageClass page |
	pageCode := aStream next asInteger.
	pageClass := self allSubclasses detect: [ :class | class pageCode = pageCode ].
	page := pageClass new.
	page keySize: keySize.
	page valueSize: valueSize.
	^page readFrom: aStream.
]

{ #category : #utilities }
SoilIndexPage >> headerSize [ 
	^ 1 "pageCode" + self indexSize
]

{ #category : #accessing }
SoilIndexPage >> index [
	^ index
]

{ #category : #accessing }
SoilIndexPage >> index: anInteger [ 
	index := anInteger
]

{ #category : #writing }
SoilIndexPage >> indexSize [
	^ 2
]

{ #category : #testing }
SoilIndexPage >> isDirty [
	^ dirty 
]

{ #category : #testing }
SoilIndexPage >> isLastPage [
	self shouldBeImplemented.
]

{ #category : #accessing }
SoilIndexPage >> pageSize [
	^ pageSize
]

{ #category : #accessing }
SoilIndexPage >> pageSize: anInteger [ 
	pageSize := anInteger 
]

{ #category : #printing }
SoilIndexPage >> printOn: aStream [ 
	aStream << 'page : #' << index asString
]

{ #category : #writing }
SoilIndexPage >> readFrom: aStream [ 
	dirty := false.
	"we do not read the pageCode here as it was read already"
	self readIndexFrom: aStream
]

{ #category : #writing }
SoilIndexPage >> readIndexFrom: aStream [ 
	index := (aStream next: self indexSize) asInteger.

]

{ #category : #writing }
SoilIndexPage >> writeHeaderOn: aStream [ 
	aStream
		nextPut: self class pageCode;
		nextPutAll: (index asByteArrayOfSize: self indexSize)
]

{ #category : #writing }
SoilIndexPage >> writeOn: aStream [ 
	dirty := false.
	self writeHeaderOn: aStream
]