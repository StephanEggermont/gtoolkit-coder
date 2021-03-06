Class {
	#name : #GtPackagesCoderElement,
	#superclass : #BlElement,
	#instVars : [
		'packagesCoder',
		'contentPane',
		'selectedCoder'
	],
	#category : #'GToolkit-Coder-UI'
}

{ #category : #'building ui' }
GtPackagesCoderElement >> buildAddClassButton [
	| look |
	^ BrButton new
		label: 'Add class';
		look:
			BrGlamorousButtonWithIconLook
				+
					(look := BrGlamorousWithDropdownLook
						handle: [ BrButton new
								look:
									BrGlamorousButtonWithIconLook - BrGlamorousWithLabelTooltipLook
										- BrGlamorousButtonExteriorLook;
								icon: BrGlamorousIcons add asElement;
								yourself ]
						content: [ | coder |
							coder := GtClassDefinitionCoder new
								expanded: true;
								source:
									'Object subclass: #NameOfSubclass
	instanceVariableNames: ''''
	classVariableNames: ''''
	package: ''''';
								yourself.
							coder announcer
								when: GtCoderEvaluationAnnouncement
								do: [ :e | 
									look hide.
									self updateSelection: (packagesCoder coderForClass: e value) ].
							coder asElement
								hFitContent;
								vFitContent;
								margin: (BlInsets all: 10);
								yourself ]);
		icon: BrGlamorousIcons add asElement;
		yourself
]

{ #category : #'as yet unclassified' }
GtPackagesCoderElement >> buildClassHierarchyTree [
	| classes tree |
	classes := (selectedCoder theClass withAllSuperclasses
		, selectedCoder theClass allSubclasses) asIdentitySet.
	tree := BrSimpleTree new
		constraintsDo: [ :c | 
			c horizontal fitContent.
			c vertical matchParent ];
		items: {(packagesCoder coderForClass: ProtoObject)}
			children: [ :anObject | 
			((anObject theClass subclasses select: [ :c | classes includes: c ])
				sorted: [ :a :b | a name < b name ])
				collect: [ :c | packagesCoder coderForClass: c ] ];
		stencil:
			(BrSimpleTreeRowStencilBuilder new
				text: [ :anObject | anObject name asRopedText glamorousRegularFontAndSize ]);
		yourself.
	tree
		when: BrSelectionChanged
		do: [ :anEvent | 
			tree
				selectedNodeDo: [ :aNode | 
					selectedCoder := aNode value.
					self updateCoder.
					tree hasParent
						ifTrue: [ tree parent removeChildNamed: #package.
							tree parent
								addChildFirst: self buildPackageHierarchyTree
								as: #package ] ] ].
	self selectAndScrollTo: selectedCoder in: tree.
	^ tree
]

{ #category : #'building ui' }
GtPackagesCoderElement >> buildContentPane [
	contentPane := BlElement new.
	contentPane layout: BlLinearLayout horizontal.
	contentPane padding: (BlInsets all: 5).
	contentPane
		constraintsDo: [ :c | 
			c horizontal matchParent.
			c vertical matchParent ].
	^ contentPane
]

{ #category : #'building ui' }
GtPackagesCoderElement >> buildPackageHierarchyTree [
	| tree |
	tree := BrSimpleTree new
		constraintsDo: [ :c | 
			c horizontal fitContent.
			c vertical matchParent ];
		items: {packagesCoder}
			children: [ :anObject | 
			anObject packageTreeCoders
				asSortedCollection: [ :a :b | a name < b name ] ];
		stencil:
			(BrSimpleTreeRowStencilBuilder new
				text: [ :anObject | anObject name asRopedText glamorousRegularFontAndSize ]);
		yourself.
	tree
		when: BrSelectionChanged
		do: [ :anEvent | 
			tree
				selectedNodeDo: [ :aNode | 
					selectedCoder := aNode value.
					self updateCoder.
					tree hasParent
						ifTrue: [ tree parent removeChildNamed: #class.
							(selectedCoder isKindOf: GtClassCoder)
								ifTrue: [ tree parent addChild: self buildClassHierarchyTree as: #class ] ] ] ].
	self selectAndScrollTo: selectedCoder in: tree.
	^ tree
]

{ #category : #'building ui' }
GtPackagesCoderElement >> buildPackageList [
	| element |
	element := BrSimpleList new.
	element stencil: [:each | each asCardElement
					 constraintsDo: [:c | c horizontal matchParent.
							c vertical fitContent ];
					 yourself ].
	element display: (packagesCoder coders asSortedCollection: [:a :b | a name < b name ]).
	^element
]

{ #category : #'building ui' }
GtPackagesCoderElement >> buildPackagesElement [
	| element |
	element := BlElement new.
	element layout: BlLinearLayout vertical.
	element padding: (BlInsets all: 5).
	element
		constraintsDo: [ :c | 
			c horizontal matchParent.
			c vertical matchParent ].
	element
		addChild:
			(BrLabel new
				margin: (BlInsets left: 10);
				look: (BrGlamorousLabelLook new bold glamorousRegularFont fontSize: 20);
				text: packagesCoder name).
	element
		addChild:
			(BrLabel new
				margin: (BlInsets left: 10);
				look: BrGlamorousLabelLook new glamorousRegularFont;
				text: packagesCoder coders size printString , ' Packages').
	element addChild: self buildPackageList.
	^ element
]

{ #category : #'building ui' }
GtPackagesCoderElement >> buildPackagesTreeButton [
	| look |
	^ BrToggle new
		label: 'Show Package Tree';
		look:
			BrGlamorousButtonWithIconLook
				+
					(look := BrGlamorousWithDropdownLook
						handle: [ BrButton new
								look:
									BrGlamorousButtonWithIconLook - BrGlamorousWithLabelTooltipLook
										- BrGlamorousButtonExteriorLook;
								icon: BrGlamorousIcons tree asElement;
								yourself ]
						content: [ | content |
							content := BlElement new
								layout: BlLinearLayout horizontal;
								margin: (BlInsets all: 10);
								constraintsDo: [ :c | 
									c horizontal fitContent.
									c vertical exact: 400 ];
								addChild: self buildPackageHierarchyTree as: #package;
								yourself.
							(selectedCoder isKindOf: GtClassCoder)
								ifTrue: [ content addChild: self buildClassHierarchyTree as: #class ].
							content ]);
		icon: BrGlamorousIcons tree asElement;
		yourself
]

{ #category : #'building ui' }
GtPackagesCoderElement >> buildSpotterButton [
	| look |
	^ BrButton new
		label: 'Search';
		look:
			BrGlamorousButtonWithIconLook
				+
					(look := BrGlamorousWithDropdownLook
						stencil: [ | model |
							model := GtSpotter new initializeWith: GtCoderSpotterStart new.
							model announcer
								when: GtSpotterActOn
								do: [ :e | 
									| item |
									item := e element.
									e actedUpon: true.
									self flag: 'FIXME candidates may be wrapped for some reason'.
									[ (item isKindOf: GtSpotterCandidate)
										and: [ item item ~~ item ] ]
										whileTrue: [ item := item item ].
									((#(singleClick doubleClick keyPressed) includes: e eventType)
										and: [ {RPackage.
											ClassDescription.
											CompiledMethod} anySatisfy: [ :f | item isKindOf: f ] ])
										ifTrue: [ look hide.
											(item isKindOf: RPackage)
												ifTrue: [ self updateSelection: (packagesCoder coderForPackage: item) ].
											(item isKindOf: ClassDescription)
												ifTrue: [ self updateSelection: (packagesCoder coderForClass: item) ].
											(item isKindOf: CompiledMethod)
												ifTrue: [ | classCoder |
													classCoder := packagesCoder
														coderForClass: item methodClass.
													self updateSelection: classCoder.
													classCoder withSelectedMethod: item ] ] ].
							BlElement new
								look:
									(BrGlamorousDropdownLook new
										handle:
											(BrButton new
												look:
													BrGlamorousButtonWithIconLook - BrGlamorousWithLabelTooltipLook
														- BrGlamorousButtonExteriorLook;
												icon: BrGlamorousIcons search asElement;
												yourself);
										content:
											(GtSpotterElement new
												spotterModel: model;
												constraintsDo: [ :c | 
													c horizontal exact: 600.
													c vertical exact: 400 ];
												margin: (BlInsets all: 1);
												geometry: (BlRectangle cornerRadius: 4);
												in: [ :e | 
													self
														flag: 'FIXME need to remove original listener to avoid phlow inspect'.
													model announcer subscriptions subscriptions
														detect: [ :g | 
															g announcementClass == GtSpotterSelectedCandidateChanged
																and: [ g action isMessageSend
																		and: [ g action selector = #onCandidateSelected:
																				and: [ g action receiver == e ] ] ] ]
														ifFound: [ :g | g announcer subscriptions remove: g ] ];
												yourself);
										yourself);
								background: BrGlamorousColors secondaryHeaderBackgroundColor;
								yourself ]);
		icon: BrGlamorousIcons search asElement;
		yourself
]

{ #category : #'building ui' }
GtPackagesCoderElement >> buildToolbar [
	^ BrToolbar new
		look: BrGlamorousToolbarLook new;
		padding:
			(BlInsets
				top: 10
				left: 0
				bottom: 0
				right: 5);
		constraintsDo: [ :c | 
			c ignoreByLayout.
			c ignored horizontal alignRight.
			c ignored vertical alignTop ];
		addItem: self buildSpotterButton;
		addItem: self buildPackagesTreeButton;
		addItem: self buildAddClassButton;
		yourself
]

{ #category : #'initialize-release' }
GtPackagesCoderElement >> coders: aPackagesCoder [
  packagesCoder := aPackagesCoder.
  self updateSelection: packagesCoder.
  packagesCoder when: GtPackagesCoderNavigationAnnouncement do: [:evt |  self updateSelection: evt coder ]
]

{ #category : #'initialize-release' }
GtPackagesCoderElement >> initialize [
	super initialize.
	self
		constraintsDo: [ :c | 
			c horizontal matchParent.
			c vertical matchParent ].
	self addChild: self buildContentPane.
	self addChild: self buildToolbar
]

{ #category : #private }
GtPackagesCoderElement >> selectAndScrollTo: anObject in: aTree [
	aTree viewModel root
		allChildrenNodesBreadthFirstDo: [ :treeNode | 
			treeNode ensureChildNodesComputed.
			anObject = treeNode value
				ifTrue: [ treeNode withAllParentNodesDo: [ :node | node expand ].
					aTree selectOne: treeNode globalIndexInTree.
					(aTree childNamed: #tree)
						scrollToPosition: treeNode globalIndexInTree ] ]
]

{ #category : #events }
GtPackagesCoderElement >> updateCoder [
	| coderElement |
	contentPane
		childNamed: #coder
		ifFound: [ :element | element removeFromParent ]
		ifNone: [  ].
	coderElement := selectedCoder = packagesCoder
		ifTrue: [ self buildPackagesElement ]
		ifFalse: [ selectedCoder asElement ].
	contentPane addChild: coderElement as: #coder
]

{ #category : #events }
GtPackagesCoderElement >> updateSelection: aCoder [
	selectedCoder := aCoder.
	self updateCoder
]
