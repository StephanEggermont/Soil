Class {
	#name : #SoilPagedIndexStore,
	#superclass : #Object,
	#instVars : [
		'pages',
		'index',
		'pagesMutex'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #'as yet unclassified' }
SoilPagedIndexStore >> flush [
	^ self subclassResponsibility
]

{ #category : #'as yet unclassified' }
SoilPagedIndexStore >> headerPage [
	^ self pageAt: 1
]

{ #category : #accessing }
SoilPagedIndexStore >> highestPageIndex [ 
	^ pages size
]

{ #category : #accessing }
SoilPagedIndexStore >> index [
	^ index
]

{ #category : #accessing }
SoilPagedIndexStore >> index: aCollection [ 
	index := aCollection
]

{ #category : #initialization }
SoilPagedIndexStore >> initialize [ 
	super initialize.
	pages := Dictionary new.
	pagesMutex := Mutex new

]

{ #category : #testing }
SoilPagedIndexStore >> isCopyOnWrite [
	^ false
]

{ #category : #acessing }
SoilPagedIndexStore >> lastPageIndex [
	^ self headerPage lastPageIndex
]

{ #category : #'instance creation' }
SoilPagedIndexStore >> newPage [
	^ index newPage
]

{ #category : #accessing }
SoilPagedIndexStore >> nextIndex [
	^ pages size + 1
]

{ #category : #'as yet unclassified' }
SoilPagedIndexStore >> nextPageIndex [
	^ self headerPage nextPageIndex
]

{ #category : #accessing }
SoilPagedIndexStore >> pageAt: anInteger [ 
	^ pagesMutex critical: [  
		pages 
			at: anInteger 
			ifAbsent: [ self pageFaultAt: anInteger ] ]
]

{ #category : #accessing }
SoilPagedIndexStore >> pageAt: anInteger put: aPage [ 
	pagesMutex critical: [  
		pages 
			at: anInteger 
			put: aPage ]
]

{ #category : #'as yet unclassified' }
SoilPagedIndexStore >> pageFaultAt: anInteger [ 
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilPagedIndexStore >> pages [
	^ pages
]