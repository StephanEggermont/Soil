Class {
	#name : #SOObjectIndexTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests'
}

{ #category : #tests }
SOObjectIndexTest >> testInitializeOnStream [
	| index bytes prefix fileVersion fuelVersion |
	bytes := ByteArray streamContents: [ :stream |
		index := SOObjectIndexFile new stream: stream.
		index initializeDatabase ].
	self assert: bytes size equals: index headerSize + index objectIndexSize.
	prefix := bytes copyFrom: 1 to: index prefix size.
	self assert: prefix equals: 'SOIL|OBJECT INDEX' asByteArray.
	fileVersion := bytes copyFrom: index prefix size + 1 to: (index prefix size + index fileVersionSize).
	self assert: fileVersion asInteger equals: 1.
	fuelVersion := bytes copyFrom: index prefix size + index fileVersionSize + 1 to: (index prefix size + index fileVersionSize + index fuelVersionSize).
	self assert: fuelVersion asInteger equals: 1
	 
]

{ #category : #tests }
SOObjectIndexTest >> testInitializedFileVersion [
	| index bytes newIndex |
	bytes := ByteArray streamContents: [ :stream |
		index := SOObjectIndexFile new stream: stream.
		index initializeDatabase ].
	newIndex := SOObjectIndexFile new 
		stream: bytes readStream;
		readHeader.
	self assert: newIndex fileVersion equals: 1
]

{ #category : #tests }
SOObjectIndexTest >> testInitializedFuelVersion [
	| index bytes newIndex |
	bytes := ByteArray streamContents: [ :stream |
		index := SOObjectIndexFile new stream: stream.
		index initializeDatabase ].
	newIndex := SOObjectIndexFile new 
		stream: bytes readStream;
		readHeader.
	self assert: newIndex fuelVersion equals: 1
]