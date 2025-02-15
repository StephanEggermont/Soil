Class {
	#name : #SoilDatabaseJournal,
	#superclass : #Object,
	#instVars : [
		'soil',
		'transactionJournals'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #visting }
SoilDatabaseJournal >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitDatabaseJournal: self
]

{ #category : #adding }
SoilDatabaseJournal >> addTransactionJournal: aTransactionJournal [ 
	transactionJournals 
		at: aTransactionJournal index
		put: aTransactionJournal

]

{ #category : #copying }
SoilDatabaseJournal >> copyFrom: start to: end [ 
| journals |
	journals := OrderedCollection new.
	self transactionJournalsStartingAt: start do: [ :j |
		(j index <= end) ifTrue: [ journals add: j ] ]. 
	^ SoilMemoryDatabaseJournal new 
		soil: soil;
		transactionJournals: journals
]

{ #category : #enumerating }
SoilDatabaseJournal >> do: aBlock [ 
	transactionJournals do: aBlock
]

{ #category : #'as yet unclassified' }
SoilDatabaseJournal >> importEntry: aSoilTransactionJournal [ 
	self addTransactionJournal: aSoilTransactionJournal
]

{ #category : #'as yet unclassified' }
SoilDatabaseJournal >> lastIndex [
	^ self lastTransactionJournal 
		ifNotNil: [ :journal | journal index ]
		ifNil: [ 0 ]
]

{ #category : #accessing }
SoilDatabaseJournal >> lastTransactionJournal [
	| maxKey |
	maxKey := 0.
	transactionJournals keysAndValuesDo: [ :key :value |
		(key > maxKey) ifTrue: [ maxKey := key ] ].
	^ transactionJournals at: maxKey		
]

{ #category : #accessing }
SoilDatabaseJournal >> soil: aSoil [ 
	soil := aSoil
]

{ #category : #accessing }
SoilDatabaseJournal >> transactionJournalAt: anInteger [ 
	^ transactionJournals 
		at: anInteger 
		ifAbsentPut: [ self halt ]
]

{ #category : #accessing }
SoilDatabaseJournal >> transactionJournals: anObject [

	transactionJournals := anObject
]

{ #category : #adding }
SoilDatabaseJournal >> verifyNextJournalIndex: index [ 
	"transaction journals have a strict sequence in the same way the
	databaseVersion has. So we check that this assumption is kept"
	transactionJournals isEmpty 
		ifTrue: [ ^ self ]
		ifFalse: [ 
			((self lastTransactionJournal index + 1) = index)
				ifFalse: [ 
					Transcript show: ('journal index is not valid: current last index is ', self lastTransactionJournal index printString, ', no index to be added is ', index printString); cr ] ]
		
]
