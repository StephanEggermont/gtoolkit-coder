Class {
	#name : #GtMethodCoder,
	#superclass : #GtSourceCoder,
	#instVars : [
		'class',
		'selector',
		'methodSource',
		'subCoders',
		'isBuilt'
	],
	#category : #'GToolkit-Coder-Coders'
}

{ #category : #'instance creation' }
GtMethodCoder class >> forClass: aBehavior source: aString [
	^ self new
		forClass: aBehavior source: aString;
		yourself
]

{ #category : #'instance creation' }
GtMethodCoder class >> forExample: anExample [
	^ self new example: anExample 
]

{ #category : #'instance creation' }
GtMethodCoder class >> forMethod: aCompiledMethod [
	^ self new
		forMethod: aCompiledMethod;
		yourself
]

{ #category : #'instance creation' }
GtMethodCoder class >> forObject: anObject andSelector: aSymbol [
	^ (self forMethod: anObject class >> aSymbol)
		object: anObject;
		yourself
]

{ #category : #'instance creation' }
GtMethodCoder class >> newMethod [
	^ self new
		expanded: true;
		source: '';
		yourself
]

{ #category : #accessing }
GtMethodCoder >> addSubCoder: aMethodCoder [
	self subCoders addFirst: aMethodCoder
]

{ #category : #'add ons' }
GtMethodCoder >> baselineAddOnFor: anAST into: coderAddOns [
	<gtAstCoderAddOns: 10>
	(anAST isNil or: [ anAST methodNode isNil ])
		ifTrue: [ coderAddOns removeStylerOfType: GtCoderExpandableMethodStyler.
			^ self ].
	(class isNil or: [ (class inheritsFrom: BaselineOf) not ])
		ifTrue: [ ^ self ].
	coderAddOns addStyler: GtCoderExpandableBaselineStyler new
]

{ #category : #elements }
GtMethodCoder >> breadcrumbNamedActions [
	^ Array
		streamContents: [ :aStream | 
			| aPackage aPackageName aClass |
			aPackage := (self compiledMethod ifNil: [ self classOrMetaClass ])
				package.
			aPackageName := aPackage ifNil: [ '' ] ifNotNil: #name.
			aClass := self classOrMetaClass.
			aStream
				nextPut: aPackageName -> [ :aButton | aButton phlow spawnObject: aPackage ];
				nextPut:
					aClass name
						->
							[ :aButton | aButton phlow spawnObject: (GtClassCoder forClass: aClass) ] ]
]

{ #category : #private }
GtMethodCoder >> buildSource [
	isBuilt := true.
	[ | text |
	text := methodSource asRopedText.
	text attributes: self defaultTextAttributes.
	self sourceEditor text: text ]
		on: Error
		do: [ :ex | 
			self
				flag:
					'FIXME this is exception catching pokemon style. use better error or fail'.
			ex return ]
]

{ #category : #examples }
GtMethodCoder >> canExecuteExample [
	^ self example ifNil: [ false ] ifNotNil: [ :anExample | anExample canBeExecuted ]
]

{ #category : #accessing }
GtMethodCoder >> category [
	^ (self attributeNamed: #category)
		ifNil: [ (self classOrMetaClass notNil and: [ self selector notNil ])
				ifTrue: [ self classOrMetaClass whichCategoryIncludesSelector: self selector ] ]
]

{ #category : #accessing }
GtMethodCoder >> category: aSymbol [
	^ self attributeNamed: #category put: aSymbol
]

{ #category : #actions }
GtMethodCoder >> changeManager [
	^ RBRefactoryChangeManager instance
]

{ #category : #accessing }
GtMethodCoder >> classOrMetaClass [
	^ class ifNil: [ super classOrMetaClass ]
]

{ #category : #accessing }
GtMethodCoder >> classOrMetaClass: aBehavior [
	class := aBehavior
]

{ #category : #private }
GtMethodCoder >> clearPatternSyntaxErrors [
	self collapsedText clearAttributes: [ :each | each isKindOf: GtSourceCoderErrorAttribute ]
]

{ #category : #private }
GtMethodCoder >> collapsedVariableNode [
	^ self classOrMetaClass
		ifNotNil: [ :cls | 
			GtPharoParser
				parse: cls instanceSide name
				startingAt: GtPharoParser startingStateForStatement ]
]

{ #category : #private }
GtMethodCoder >> compile [
	| change |
	subCoders notNil
		ifTrue: [ subCoders
				do: [ :each | 
					each compile
						ifFalse: [ ^ false ] ] ].
	change := self category
		ifNil: [ RBAddMethodChange compile: self newMethodSource in: self classOrMetaClass for: self requester ]
		ifNotNil: [ :category | 
			RBAddMethodChange
				compile: self newMethodSource
				in: self classOrMetaClass
				classified: category
				for: self requester ].
	self changeManager performChange: change.
	change definedSelector
		ifNotNil: [ :sel | 
			self selector: sel.
			self compiledMethod
				ifNotNil: [ :method | 
					methodSource := method sourceCode.
					^ true ] ].
	^ false
]

{ #category : #accessing }
GtMethodCoder >> compiledMethod [
	<return: #CompiledMethod or: nil>
	^ self classOrMetaClass
		ifNotNil: [ :cls | 
			self selector
				ifNotNil: [ :sel | 
					(cls canUnderstand: sel)
						ifTrue: [ cls >> sel ] ] ]
]

{ #category : #examples }
GtMethodCoder >> debugExampleFrom: anElement [
	self isModified
		ifTrue: [ self save
			ifFalse: [ ^ self ] ].
	self example openingDebugger result
]

{ #category : #actions }
GtMethodCoder >> debugMethod [
	self isModified
		ifTrue: [ self save
			ifFalse: [ ^ self ] ].
	self debug: self compiledMethod receiver: self object in: self context.
]

{ #category : #examples }
GtMethodCoder >> debugSelectionOrExampleFrom: anElement [
	| source |
	source := self selectedSource.
	source isEmpty
		ifTrue: [ ^ self debugExampleFrom: anElement ].
	^ self debugSource: source
]

{ #category : #actions }
GtMethodCoder >> debugSelectionOrMethod [
	| source |
	source := self selectedSource.
	source isEmpty
		ifTrue: [ ^ self debugMethod ].
	^ self debugSource: source
]

{ #category : #actions }
GtMethodCoder >> discardChanges [
	"Discard not-accepted changes."
	self isModified ifFalse: [ ^ self ].
	self buildSource.
]

{ #category : #private }
GtMethodCoder >> ensureBuilt [
	isBuilt
		ifTrue: [ ^ self ].
	self buildSource
]

{ #category : #private }
GtMethodCoder >> evaluateSelector: aSymbol object: anObject showPrintString: aBoolean [
	^ self 
		evaluateBlock: [ anObject perform: aSymbol ] 
		showPrintString: aBoolean
]

{ #category : #examples }
GtMethodCoder >> example [
	<return: #GtExampleWithResult or: nil>
	| anExample |
	anExample := self attributeNamed: #example.
	anExample ifNil: [ 
		anExample := self compiledMethod ifNotNil: [ :aCompiledMethod | 
			aCompiledMethod gtExample ifNotNil: #asExampleWithResult ].
		anExample ifNotNil: [ self example: anExample ] ].
	^ anExample
]

{ #category : #examples }
GtMethodCoder >> example: anExampleWithResult [
	| method |
	self
		attributeNamed: #example
		ifPresent:
			[ :anOldExampleWithResult | anOldExampleWithResult announcer unsubscribe: self ]
		ifAbsent: [ "do nothing" ].
	self
		attributeNamed: #example
		put: anExampleWithResult asExampleWithResult.
	method := anExampleWithResult method.
	(method selector = self selector
		and: [ method methodClass = self classOrMetaClass
				and: [ method sourceCode = methodSource ] ])
		ifFalse: [ self forMethod: method ].
	self example announcer weak
		when: GtExampleExecuted send: #handleExampleExecuted: to: self;
		when: GtExampleArgumentsChanged
			send: #handleExampleArgumentsChanged:
			to: self
]

{ #category : #'add ons' }
GtMethodCoder >> exampleAstFor: anAST into: coderAddOns [
	<gtAstCoderAddOns: 10>
	(self compiledMethod notNil
		and: [ anAST notNil
				and: [ anAST methodNode
						ifNotNil: [ :node | 
							node pragmas
								anySatisfy: [ :each | each isParseError not and: [ each selector = #gtExample ] ] ]
						ifNil: [ false ] ] ])
		ifFalse: [ coderAddOns removeStylerOfType: GtCoderExampleStatusStyler.
			^ self ].
	coderAddOns
		addStyler:
			(GtCoderExampleStatusStyler new
				coder: self;
				classOrMetaClass: self classOrMetaClass).
	(self canExecuteExample or: [ anAST methodNode numArgs isZero ])
		ifFalse: [ ^ self ].
	coderAddOns
		addContextAction: 'Play' translated
		icon: BrGlamorousIcons play
		action: [ :button | self playExampleFrom: button ].
	coderAddOns
		addContextAction: 'Play and Inspect' translated
		icon: BrGlamorousIcons playinspect
		action: [ :button | self playAndInspectExampleFrom: button ].
	coderAddOns
		addContextAction: 'Debug' translated
		icon: BrGlamorousIcons debug
		action: [ :button | self debugSelectionOrExampleFrom: button ]
]

{ #category : #examples }
GtMethodCoder >> exampleResult [
	<return: #GtExampleResult>
	^ self example result
]

{ #category : #acccessing }
GtMethodCoder >> explanationFor: anAST into: coderAddOns [
	<gtAstCoderAddOns: 10>
	coderAddOns removeStylerOfType: GtSourceExplanationLinkStyler.
	self explanationLink notNil
		ifTrue: [ coderAddOns addStyler: self explanationLink ].
]

{ #category : #acccessing }
GtMethodCoder >> explanationLink [
	^ self attributeNamed: #explanationLink
]

{ #category : #setter }
GtMethodCoder >> explanationLink: anExplanation [
	self explanationLink == anExplanation ifTrue: [ ^ self ].
	self attributeNamed: #explanationLink put: anExplanation.
	isBuilt ifFalse: [ ^ self ].
	self updateAddOns.
	self styleText
]

{ #category : #actions }
GtMethodCoder >> extractMethod: editorElement [
	(GtExtractMethodController new
		coder: self;
		sourceElement: editorElement) execute
]

{ #category : #private }
GtMethodCoder >> findSeparatorBetweenPatternAndBodyIn: aMethodNode [
	| startIndex char source |
	source := aMethodNode completeSource.
	startIndex := aMethodNode pattern stopPosition + 1.
	[ startIndex <= source size and: [ (char := source at: startIndex) isSeparator and: [ char ~= Character cr ] ] ]
		whileTrue: [ startIndex := startIndex + 1 ].
	^ startIndex
]

{ #category : #'initialize-release' }
GtMethodCoder >> forClass: aBehavior source: aString [
	self classOrMetaClass: aBehavior.
	methodSource := aString.
	isBuilt
		ifTrue: [ self buildSource ]
]

{ #category : #'initialize-release' }
GtMethodCoder >> forMethod: aCompiledMethod [
	self classOrMetaClass: aCompiledMethod methodClass.
	self selector: aCompiledMethod selector.
	methodSource := aCompiledMethod sourceCode.
	isBuilt
		ifTrue: [ self buildSource ]
]

{ #category : #updating }
GtMethodCoder >> format [
	methodSource := (RBParser parseMethod: self source) formattedCode.
	self buildSource
]

{ #category : #ui }
GtMethodCoder >> gtDiffViewFor: aView [
	<gtView>
	(methodSource = self newMethodSource) ifTrue: [ ^ aView ].
	^ aView textEditor
		title: 'Diff' translated;
		priority: 11;
		text: [ :anEditor | 
			GtEpiceaDiffStencil new
				from: methodSource;
				to: self newMethodSource;
				create ]
]

{ #category : #ui }
GtMethodCoder >> gtLiveFor: aView [
	^ aView explicit 
		title: 'Live';
		priority: 10;
		stencil: [ self expanded: true ]
]

{ #category : #ui }
GtMethodCoder >> gtViewAddOnFor: anAST into: coderAddOns [
	<gtAstCoderAddOns: 6>
	(self hasObjectAttribute
		and: [ anAST notNil
				and: [ anAST methodNode
						ifNotNil: [ :node | 
							node arguments size = 1
								and: [ node pragmas
										anySatisfy:
											[ :each | each isParseError not and: [ each selector = #gtView ] ] ] ]
						ifNil: [ false ] ] ])
		ifFalse: [ coderAddOns removeContextAction: 'gtView' translated.
			^ self ].
	coderAddOns
		addContextAction: 'gtView' translated
		icon: BrGlamorousIcons playinspect
		action: [ :button | self runGtViewFrom: button ]
]

{ #category : #'event handling' }
GtMethodCoder >> handleExampleArgumentsChanged: aGtExampleArgumentsChanged [
	self updateAddOns.
]

{ #category : #'event handling' }
GtMethodCoder >> handleExampleExecuted: aGtExampleExecuted [
	self styleCollapsedText.
	self styleSourceText.
]

{ #category : #accessing }
GtMethodCoder >> highlighter [
	^ self attributeNamed: #highlighter
]

{ #category : #accessing }
GtMethodCoder >> highlighter: aHighlighter [
	self highlighter == aHighlighter ifTrue: [ ^ self ].
	self attributeNamed: #highlighter put: aHighlighter.
	isBuilt ifFalse: [ ^ self ].
	self updateAddOns.
	self styleText
]

{ #category : #'add ons' }
GtMethodCoder >> highlighterFor: anAST into: coderAddOns [
	<gtAstCoderAddOns: 10>
	coderAddOns removeStylerOfType: GtSourceReferenceHighlighter.
	self highlighter notNil
		ifTrue: [ coderAddOns addStyler: self highlighter ]
]

{ #category : #'initialize-release' }
GtMethodCoder >> initialize [
	isBuilt := false.
	methodSource := ''.
	super initialize
]

{ #category : #'initialize-release' }
GtMethodCoder >> initializeAddOns [
	super initializeAddOns.
	"addOns addStyler: GtCoderCommentStyler new."
	addOns addMainAction: 'Save' translated icon: BrGlamorousIcons accept action: [ self save ].
	addOns addMainAction: 'Remove' translated icon: BrGlamorousIcons remove action: [ self remove ].
	addOns clearChanges
]

{ #category : #'initialize-release' }
GtMethodCoder >> initializeShortcuts [
	super initializeShortcuts.

	addOns
		addCollapsedShortcut: (BlShortcut new
			combination: BlKeyCombination primaryM;
			action: [ :editorElement | self browseImplementors: editorElement ]);
		addCollapsedShortcut: (BlShortcut new
			combination: BlKeyCombination primaryN;
			action: [ :editorElement | self browseReferences: editorElement ]);
		addCollapsedShortcut: (BlShortcut new
			combination: BlKeyCombination primaryB;
			action: [ :editorElement | self browseClass: editorElement ]);
			
		addShortcut: (BlShortcut new
			combination: BlKeyCombination primaryD;
			action: [ :editorElement | self playSelectionOrMethodFrom: editorElement ]);
		addShortcut: (BlShortcut new
			combination: BlKeyCombination primaryG;
			action: [ :editorElement | self playAndInspectSelectionOrMethodFrom: editorElement ]);
		addShortcut: (BlShortcut new
			combination: BlKeyCombination primaryR;
			action: [ :editorElement | self renameVariableIn: editorElement ]);
		addShortcut: (BlShortcut new
			combination: BlKeyCombination primaryE;
			action: [ :editorElement | self extractMethod: editorElement ]);
		addShortcut: (BlShortcut new
			combination: BlKeyCombination primaryS;
			action: [ self save ]);
		addShortcut: (BlShortcut new
			combination: (BlKeyCombination primaryShiftF);
			action: [ self format ])
]

{ #category : #private }
GtMethodCoder >> intervalToStyleResult [
	"If method was executed, it displays result next to the method selector."
	^ self hasSelection 
		ifTrue: [ self selectedSourceIntervalOrAll ]
		ifFalse: [ 1 to: self selector size ]
]

{ #category : #testing }
GtMethodCoder >> isBuilt [
	^ isBuilt
]

{ #category : #testing }
GtMethodCoder >> isForMethod: aCompiledMethod [
	^ self classOrMetaClass = aCompiledMethod methodClass and: [ self selector = aCompiledMethod selector ]
]

{ #category : #testing }
GtMethodCoder >> isModified [
	^ isBuilt and: [ methodSource ~= self newMethodSource ]
]

{ #category : #'add ons' }
GtMethodCoder >> isMondrianPaintMethod: aMethodNode [
	| variable |
	aMethodNode arguments size ~= 1
		ifTrue: [ ^ false ].
	('paint*With:' match: aMethodNode selector)
		ifFalse: [ ^ false ].
	variable := aMethodNode arguments first.
	aMethodNode
		nodesDo: [ :each | 
			(each isMessage and: [ each receiver = variable ])
				ifTrue: [ (GtMondrian canUnderstand: each selector)
						ifFalse: [ ^ false ] ] ].
	^ true
]

{ #category : #'event handling' }
GtMethodCoder >> methodChanged: aMethodModified [
	| aCompiledMethod |
	aCompiledMethod := self compiledMethod.
	(aCompiledMethod notNil and: [ 
		aMethodModified classAffected = aCompiledMethod methodClass
			and: [ aMethodModified selector = aCompiledMethod selector ]])
				ifFalse: [ ^ self ].
	self updateMethod: aMethodModified newMethod
]

{ #category : #'add ons' }
GtMethodCoder >> methodExpanderFor: anAST into: coderAddOns [
	<gtAstCoderAddOns: 10>
	(anAST isNil or: [ anAST methodNode isNil ])
		ifTrue: [ coderAddOns removeStylerOfType: GtCoderExpandableMethodStyler.
			^ self ].
	coderAddOns addStyler: GtCoderExpandableMethodStyler new
]

{ #category : #'add ons' }
GtMethodCoder >> modifiedMessageAstFor: anAST into: coderAddOns [
	<gtAstCoderAddOns: 1>
	self isModified
		ifTrue: [ coderAddOns
				addMainAction: 'Discard Changes' translated
				icon: BrGlamorousIcons cancel
				action: [ :button | self discardChanges ] ]
		ifFalse: [ coderAddOns removeMainAction: 'Discard Changes' translated ]
]

{ #category : #'add ons' }
GtMethodCoder >> mondrianPaintAddOnFor: anAST into: coderAddOns [
	<gtAstCoderAddOns: 7>
	(self hasObjectAttribute
		and: [ anAST notNil
				and: [ anAST methodNode
						ifNotNil: [ :node | self isMondrianPaintMethod: node ]
						ifNil: [ false ] ] ])
		ifFalse: [ coderAddOns removeContextAction: 'Mondrian' translated.
			^ self ].
	coderAddOns
		addContextAction: 'Mondrian' translated
		icon: BrGlamorousIcons playinspect
		action: [ :button | self runMondrianPaintFrom: button ]
]

{ #category : #actions }
GtMethodCoder >> newMethodSource [
	^ self newSourceText asString
]

{ #category : #updating }
GtMethodCoder >> newRbAST: aString [
	| ast |
	ast := RBParser parseFaultyMethod: aString.
	ast isParseError
		ifTrue: [ ^ ast ].
	ast methodNode
		compilationContext:
			(CompilationContext new
				class: (self classOrMetaClass ifNil: [ UndefinedObject ])).
	ast doSemanticAnalysis.
	^ ast
]

{ #category : #'instance creation' }
GtMethodCoder >> newSourceEditor [
	<return: #BrTextEditor>
	| aSourceEditor |
	aSourceEditor := super newSourceEditor.
	aSourceEditor when: BlInfiniteDataSourceChanged do: [ :event | self sourceChanged ].
	^ aSourceEditor
]

{ #category : #accessing }
GtMethodCoder >> object [
	^ self attributeNamed: #object ifAbsent: [ class ]
]

{ #category : #private }
GtMethodCoder >> parserStartingState [
	^ GtPharoParser startingStateForMethod
]

{ #category : #private }
GtMethodCoder >> patternSource [
	^ String
		streamContents: [ :stream | 
			| ast selectorParts arguments |
			ast := self rbAST.
			selectorParts := ast selectorParts.
			arguments := ast arguments.
			(selectorParts size = 1 and: [ arguments isEmpty ])
				ifTrue: [ stream nextPutAll: selectorParts first ]
				ifFalse: [ 1 to: selectorParts size do: [ :i | 
						i = 1
							ifFalse: [ stream space ].
						stream
							nextPutAll: (selectorParts at: i);
							space;
							nextPutAll: (arguments at: i) name ] ] ]
]

{ #category : #examples }
GtMethodCoder >> playAndInspectExampleFrom: anElement [
	self runExample.
	anElement phlow spawnObject: self exampleResult returnValue.
]

{ #category : #actions }
GtMethodCoder >> playAndInspectFrom: anElement [
	"Save and execute method"
	| anObject |
	self isModified
		ifTrue: [ self save
				ifFalse: [ ^ self ] ].
	anObject := self evaluateSelector: self selector object: self object showPrintString: false.
	anElement phlow spawnObject: anObject.
]

{ #category : #actions }
GtMethodCoder >> playAndInspectSelectionOrMethodFrom: anElement [
	"If there is no selection, it saves and exexute method"
	self hasSelection 
		ifTrue: [ self doItAndGoSelection: anElement ]
		ifFalse: [ self playAndInspectFrom: anElement ]
]

{ #category : #examples }
GtMethodCoder >> playExampleFrom: anElement [
	self runExample
]

{ #category : #actions }
GtMethodCoder >> playFrom: anElement [
	self isModified
		ifTrue: [ self save
				ifFalse: [ ^ self ] ].
	self evaluateSelector: self selector object: self object showPrintString: false.
	
]

{ #category : #actions }
GtMethodCoder >> playSelectionOrMethodFrom: anElement [
	"If there is no selection, it saves and exexute method"
	self hasSelection 
		ifTrue: [ self doItSelection ]
		ifFalse: [ self playFrom: anElement ]
]

{ #category : #elements }
GtMethodCoder >> previewElement [
	^ (self class forClass: class source: methodSource)
		expanded: true;
		asElement
]

{ #category : #printing }
GtMethodCoder >> printOn: aStream [
	super printOn: aStream.
	aStream 
		nextPut: $(;
		nextPutAll: self classOrMetaClass asString; 
		nextPutAll: '>>#';
		nextPutAll: self selector asString;  
		nextPut: $)
]

{ #category : #private }
GtMethodCoder >> referencesFilterForCollapsed [
	^ self selectorForCollapsed
		ifNil: [ super referencesFilterForCollapsed ]
		ifNotNil: [ :sym | self referencesFilterForSymbol: sym ]
]

{ #category : #actions }
GtMethodCoder >> remove [
	^ class removeSelector: selector
]

{ #category : #accessing }
GtMethodCoder >> removeSubCoder: aMethodCoder [
	self subCoders remove: aMethodCoder ifAbsent: [  ]
]

{ #category : #actions }
GtMethodCoder >> renameVariableIn: editorElement [
	GtRenameAction pharoRenameLocalsOn: editorElement
]

{ #category : #examples }
GtMethodCoder >> runExample [
	self isModified
		ifTrue: [ self save
				ifFalse: [ ^ self ] ].
	self example run.
	self styleCollapsedText.
	self styleSourceText
]

{ #category : #actions }
GtMethodCoder >> runGtViewFrom: anElement [
	| view |
	self isModified
		ifTrue: [ self save
				ifFalse: [ ^ self ] ].
	view := self object perform: self selector with: GtPhlowEmptyView new.
	anElement
		fireEvent:
			(GtPhlowObjectToSpawn new
				object: view;
				sourceElement: anElement)
]

{ #category : #actions }
GtMethodCoder >> runMondrianPaintFrom: anElement [
	| mondrian |
	self isModified
		ifTrue: [ self save
				ifFalse: [ ^ self ] ].
	mondrian := GtMondrian new.
	self object perform: self selector with: mondrian.
	anElement
		fireEvent:
			(GtPhlowObjectToSpawn new
				object: mondrian;
				sourceElement: anElement)
]

{ #category : #actions }
GtMethodCoder >> save [
	^ self validateSyntax
		and: [ self compile
				and: [ self buildSource.
					true ] ]
]

{ #category : #accessing }
GtMethodCoder >> selector [
	^ selector
]

{ #category : #accessing }
GtMethodCoder >> selector: aSymbol [
	selector := aSymbol
]

{ #category : #private }
GtMethodCoder >> selectorForCollapsed [
	self sourceAst
		withAllNodesOfType: GtPharoMethodPatternNode
		do: [ :node | ^ node selector ].
	^ super selectorForCollapsed
]

{ #category : #private }
GtMethodCoder >> skipBlankLinesIn: source at: startIndex [
	| char index |
	index := startIndex.
	[ index <= source size and: [ (char := source at: index) = Character cr or: [ char = Character lf ] ] ]
		whileTrue: [ index := index + 1 ].
	^ index
]

{ #category : #elements }
GtMethodCoder >> stylerView: anElement [
	self ensureBuilt.
	super stylerView: anElement.

]

{ #category : #accessing }
GtMethodCoder >> subCoders [
	^ subCoders ifNil: [ subCoders := OrderedCollection new ]
]

{ #category : #subscriptions }
GtMethodCoder >> subscribeToSystem [
	SystemAnnouncer uniqueInstance weak
		when: MethodModified send: #methodChanged: to: self
]

{ #category : #'add ons' }
GtMethodCoder >> unaryMessageAddOnFor: anAST into: coderAddOns [
	<gtAstCoderAddOns: 20>
	(self hasObjectAttribute
		and: [ anAST notNil
				and: [ anAST methodNode
						ifNotNil: [ :node | node arguments isEmpty ]
						ifNil: [ false ] ] ])
		ifFalse: [ coderAddOns removeContextAction: 'Play' translated.
			coderAddOns removeContextAction: 'Play and Inspect' translated.
			coderAddOns removeContextAction: 'Debug' translated.
			^ self ].
	coderAddOns
		addContextAction: 'Play' translated
		icon: BrGlamorousIcons play
		action: [ :button | self playSelectionOrMethodFrom: button ].
	coderAddOns
		addContextAction: 'Play and Inspect' translated
		icon: BrGlamorousIcons playinspect
		action: [ :button | self playAndInspectSelectionOrMethodFrom: button ].
	coderAddOns
		addContextAction: 'Debug' translated
		icon: BrGlamorousIcons debug
		action: [ :button | self debugSelectionOrMethod ]
]

{ #category : #'event handling' }
GtMethodCoder >> updateCollapsedSource [
	self expanded
		ifTrue: [ ^ self ].
	[ | patternText |
	patternText := self patternSource asRopedText.
	patternText attributes: self defaultTextAttributes.
	self collapsedSource: patternText ]
		on: Error
		do: [ :ex | 
			self flag: 'FIXME do not do pokemon exception catching'.
			super updateCollapsedSource ]
]

{ #category : #updating }
GtMethodCoder >> updateMethod: aCompiledMethod [
	self forMethod: aCompiledMethod.
	self buildSource
]

{ #category : #private }
GtMethodCoder >> validateSyntax [
	subCoders notNil
		ifTrue: [ subCoders
				do: [ :each | 
					each validateSyntax
						ifFalse: [ ^ false ] ] ].
	^ super validateSyntax
]
