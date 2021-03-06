Class {
	#name : #GtClassCoderElement,
	#superclass : #BlElement,
	#instVars : [
		'classCoder',
		'container',
		'contentPane',
		'contentTabs'
	],
	#category : #'GToolkit-Coder-UI'
}

{ #category : #callbacks }
GtClassCoderElement >> actOnClassUpdated [
	self classCoder navigationModel
		updateSelectionWith: self classCoder theClass.
	self updateContentTabs
]

{ #category : #callbacks }
GtClassCoderElement >> actOnPackageUpdated: ann [
	self classCoder navigationModel 
		updateSelectionWith: ann package.
	self removeContentTabs
]

{ #category : #'building ui' }
GtClassCoderElement >> buildClassLabel [
	^ BrLabel new
		margin: (BlInsets left: 10);
		look: (BrGlamorousLabelLook new bold glamorousRegularFont fontSize: 20);
		text: classCoder name
]

{ #category : #'building ui' }
GtClassCoderElement >> buildContentPane [
	contentPane := BlElement new.
	contentPane layout: BlLinearLayout vertical.
	contentPane constraintsDo: [ :c | 
		c horizontal matchParent.
		c vertical matchParent ].
	contentPane addChild: self buildClassLabel.
	contentPane addChild: self buildParentLink.
	contentPane addChild: self buildContentTabs.
	^ contentPane
]

{ #category : #'building ui' }
GtClassCoderElement >> buildContentTabs [
	| tabPragmas  |
	tabPragmas := self classViewPragmas.
	contentTabs := BrTabGroup new.
	contentTabs look: BrGlamorousTabGroupLook new.
	contentTabs constraintsDo: [ :c | c linear weight: 2 ].
	tabPragmas
		do: [ :each | 
			classCoder theClass
				perform: each method selector
				with: contentTabs
				with: classCoder ].
	^ contentTabs
]

{ #category : #'building ui' }
GtClassCoderElement >> buildParentLink [
	| element superclassElement packageElement packageCoder |
	element := BlElement new.
	element layout: BlLinearLayout new beVertical.
	element
		constraintsDo: [ :c | 
			c horizontal matchParent.
			c vertical fitContent ].
	classCoder theClass superclass notNil
		ifTrue: [ superclassElement := BlElement new.
			superclassElement layout: BlLinearLayout new beHorizontal.
			superclassElement
				constraintsDo: [ :c | 
					c horizontal matchParent.
					c vertical fitContent ].
			superclassElement
				addChild:
					(BrLabel new
						margin: (BlInsets left: 10);
						look: BrGlamorousLabelLook new glamorousRegularFont;
						text: 'Super: ').
			superclassElement
				addChild:
					(BrButton new
						look:
							(BrGlamorousButtonExteriorLook new borderPaint: Color transparent)
								+ BrGlamorousLabelLook new glamorousRegularFont;
						label: classCoder theClass superclass name;
						action: [ | coder |
							coder := GtClassCoder forClass: classCoder theClass superclass.
							self
								allParentsDetect: [ :each | each isKindOf: GtPackagesCoderElement ]
								ifFound: [ :p | p updateSelection: coder ]
								ifNone: [ self phlow spawnObject: coder ] ]).
			element addChild: superclassElement ].
	packageElement := BlElement new.
	packageCoder := GtPackageCoder
		forPackage: classCoder theClass package.
	packageElement layout: BlLinearLayout new beHorizontal.
	packageElement
		constraintsDo: [ :c | 
			c horizontal matchParent.
			c vertical fitContent ].
	packageElement
		addChild:
			(BrLabel new
				margin: (BlInsets left: 10);
				look: BrGlamorousLabelLook new glamorousRegularFont;
				text: 'In: ').
	packageElement
		addChild:
			(BrButton new
				look:
					(BrGlamorousButtonExteriorLook new borderPaint: Color transparent)
						+ BrGlamorousLabelLook new glamorousRegularFont;
				label: packageCoder name;
				action: [ self
						allParentsDetect: [ :each | each isKindOf: GtPackagesCoderElement ]
						ifFound: [ :p | p updateSelection: packageCoder ]
						ifNone: [ self phlow spawnObject: packageCoder ] ]).
	(packageCoder packageTagForClass: classCoder theClass)
		ifNotNil: [ :tagCoder | 
			packageElement
				addChild:
					(BrLabel new
						margin: (BlInsets left: 5);
						look: BrGlamorousLabelLook new glamorousRegularFont;
						text: 'Tag: ').
			packageElement
				addChild:
					(BrButton new
						look:
							(BrGlamorousButtonExteriorLook new borderPaint: Color transparent)
								+ BrGlamorousLabelLook new glamorousRegularFont;
						label: tagCoder name;
						action: [ self
								allParentsDetect: [ :each | each isKindOf: GtPackagesCoderElement ]
								ifFound: [ :p | p updateSelection: tagCoder ]
								ifNone: [ self phlow spawnObject: tagCoder ] ]) ].
	element addChild: packageElement.
	^ element
]

{ #category : #accessing }
GtClassCoderElement >> classCoder [
	^ classCoder
]

{ #category : #accessing }
GtClassCoderElement >> classCoder: aCoder [
	classCoder := aCoder.
	classCoder
		when: GtCoderClassUpdatedAnnouncement
			do: [ self actOnClassUpdated ];
		when: GtCoderPackageUpdatedAnnouncement
			do: [ :ann | self actOnPackageUpdated: ann ].
	container ifNotNil: #removeFromParent.
	container := self buildContentPane.
	self addChildFirst: container
]

{ #category : #private }
GtClassCoderElement >> classViewPragmas [
	| pragmas |
	pragmas := Pragma
		allNamed: #gtClassView:
		from: classCoder theClass class
		to: Behavior.
	^ pragmas
		asSortedCollection: [ :a :b | a arguments first < b arguments first ]
]

{ #category : #subscriptions }
GtClassCoderElement >> definitionChanged: anAnnouncement [
	anAnnouncement classAffected == classCoder theClass
		ifFalse: [ ^ self ].
	self updateContentTabs
]

{ #category : #initialization }
GtClassCoderElement >> initialize [
	super initialize.
	self
		layout: BlLinearLayout vertical;
		constraintsDo: [ :c | 
			c horizontal matchParent.
			c vertical matchParent ].
	SystemAnnouncer uniqueInstance weak
		when:
			ClassModificationApplied , ClassModifiedClassDefinition
				, ClassParentRenamed , ClassRenamed
		send: #definitionChanged:
		to: self
]

{ #category : #'updating ui' }
GtClassCoderElement >> removeContentTabs [
	contentTabs
		ifNotNil: [ contentPane removeChild: contentTabs.
			contentTabs := nil ]
]

{ #category : #'updating ui' }
GtClassCoderElement >> updateContentTabs [
	| childIndex |
	contentTabs
		ifNil: [ childIndex := contentPane children size + 1 ]
		ifNotNil: [ childIndex := contentPane childIndexOf: contentTabs ].
	self removeContentTabs.
	contentTabs := self buildContentTabs.
	contentPane addChild: contentTabs asElement at: childIndex
]
