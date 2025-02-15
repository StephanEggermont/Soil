Class {
	#name : #SoilTransactionJournalEntry,
	#superclass : #SoilJournalEntry,
	#instVars : [
		'transactionId'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #testing }
SoilTransactionJournalEntry class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilTransactionJournalEntry
]

{ #category : #'instance creation' }
SoilTransactionJournalEntry class >> readTransactionIdFrom: aStream [ 
	aStream next.
	^ (aStream next: 8) asInteger
]

{ #category : #accessing }
SoilTransactionJournalEntry >> container [
	^ self subclassResponsibility
]

{ #category : #testing }
SoilTransactionJournalEntry >> isCommitEntry [
	^ false
]

{ #category : #testing }
SoilTransactionJournalEntry >> isTransactionEntry [ 
	^ true
]

{ #category : #accessing }
SoilTransactionJournalEntry >> oldValue [
	^ nil
]

{ #category : #writing }
SoilTransactionJournalEntry >> readFrom: aStream [ 
	"skip because the type code is already read"
	transactionId := (aStream next: 8) asInteger
]

{ #category : #accessing }
SoilTransactionJournalEntry >> transactionId [

	^ transactionId
]

{ #category : #accessing }
SoilTransactionJournalEntry >> transactionId: anObject [

	transactionId := anObject
]

{ #category : #validating }
SoilTransactionJournalEntry >> validateIn: aSoilTransaction [ 
	
]

{ #category : #writing }
SoilTransactionJournalEntry >> writeOn: aStream [ 
	super writeOn: aStream.
	aStream 
		nextPutAll: (transactionId asByteArrayOfSize: 8)

]
