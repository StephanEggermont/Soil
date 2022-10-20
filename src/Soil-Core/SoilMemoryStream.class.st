Class {
	#name : #SoilMemoryStream,
	#superclass : #Object,
	#instVars : [
		'stream'
	],
	#category : #'Soil-Core'
}

{ #category : #'instance creation' }
SoilMemoryStream class >> on: aStream [ 
	^ self new 
		stream: aStream
]

{ #category : #accessing }
SoilMemoryStream >> contents [
	^ stream flush; contents
]

{ #category : #accessing }
SoilMemoryStream >> flush [
	stream flush
]

{ #category : #writing }
SoilMemoryStream >> nextPutByte: anInteger [ 
	stream nextPut: anInteger 
]

{ #category : #'as yet unclassified' }
SoilMemoryStream >> nextPutBytesFrom: aCollection len: anInteger [ 
	stream putBytesFrom: aCollection len: anInteger 

]

{ #category : #accessing }
SoilMemoryStream >> stream: aStream [ 
	stream := aStream
]