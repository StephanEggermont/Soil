Class {
	#name : #SoilSetup,
	#superclass : #Object,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #'as yet unclassified' }
SoilSetup >> cacheMetaRecords: anInteger [
	soil objectRepository cacheSegmentAt: 0 upTo: anInteger  
]

{ #category : #'as yet unclassified' }
SoilSetup >> cacheObjectRecords: anInteger [
	1 to: soil objectRepository segments size do: [:n |
		soil objectRepository cacheSegmentAt: n upTo: anInteger ]
]

{ #category : #'as yet unclassified' }
SoilSetup >> cacheRecords [
	self cacheRecords: self defaultCacheRecordsSize
]

{ #category : #'as yet unclassified' }
SoilSetup >> cacheRecords: anInteger [
	self 
		cacheMetaRecords: anInteger;
		cacheObjectRecords: anInteger
]

{ #category : #'as yet unclassified' }
SoilSetup >> defaultCacheRecordsSize [
	^ 1000
]

{ #category : #accessing }
SoilSetup >> soil: aSoil [ 
	soil := aSoil
]