Class {
	#name : #GtSearchMethodsWithClassPatternFilter,
	#superclass : #GtSearchMethodsFilter,
	#instVars : [
		'pattern'
	],
	#category : #'GToolkit-Coder-Filters'
}

{ #category : #'instance creation' }
GtSearchMethodsWithClassPatternFilter class >> pattern: aString [
	^ self new
		pattern: aString;
		yourself
]

{ #category : #printing }
GtSearchMethodsWithClassPatternFilter >> gtDisplayOn: stream [
	stream
		nextPutAll: self pattern printString;
		nextPutAll: ' classes matching'
]

{ #category : #testing }
GtSearchMethodsWithClassPatternFilter >> includesMethod: aCompiledMethod [
	| aClassName |
	aClassName := aCompiledMethod methodClass name asLowercase.
	^ pattern isEmpty or: [ (aClassName indexOfSubCollection: pattern asLowercase) > 0 ]
]

{ #category : #accessing }
GtSearchMethodsWithClassPatternFilter >> pattern [
	^ pattern
]

{ #category : #accessing }
GtSearchMethodsWithClassPatternFilter >> pattern: aString [
	pattern := aString
]
