Class {
	#name : 'SimdJSONObjectMapping',
	#superclass : 'SimdJSONMapping',
	#instVars : [
		'subjectClass',
		'properties',
		'allowNil'
	],
	#category : 'SimdJSON-Mapping',
	#package : 'SimdJSON',
	#tag : 'Mapping'
}

{ #category : 'initialize-release' }
SimdJSONObjectMapping >> allowNil [
	"Set that I will allow nil/null values when I read/expect an object"

	allowNil := true

]

{ #category : 'accessing' }
SimdJSONObjectMapping >> identifier [
	^ subjectClass

]

{ #category : 'initialize-release' }
SimdJSONObjectMapping >> initialize [
	super initialize.
	properties := OrderedCollection new.
	allowNil := false

]

{ #category : 'mapping' }
SimdJSONObjectMapping >> mapAccessor: accessor [
	^ self mapAccessor: accessor to: accessor

]

{ #category : 'mapping' }
SimdJSONObjectMapping >> mapAccessor: accessor mutator: mutator to: propertyName [
	^ self
		mapProperty: propertyName
		getter: [ :object | object perform: accessor ]
		setter: [ :object :value | object perform: mutator with: value ]

]

{ #category : 'mapping' }
SimdJSONObjectMapping >> mapAccessor: accessor to: propertyName [
	^ self
		mapProperty: propertyName
		getter: [ :object | object perform: accessor ]
		setter: [ :object :value | object perform: accessor asMutator with: value ]

]

{ #category : 'mapping' }
SimdJSONObjectMapping >> mapAccessors: accessors [
	^ accessors collect: [ :each | self mapAccessor: each ]

]

{ #category : 'convenience' }
SimdJSONObjectMapping >> mapAllInstVars [
	^ self mapInstVars: subjectClass allInstVarNames

]

{ #category : 'mapping' }
SimdJSONObjectMapping >> mapInstVar: instVarName [
	^ self mapInstVar: instVarName to: instVarName

]

{ #category : 'mapping' }
SimdJSONObjectMapping >> mapInstVar: instVarName to: propertyName [
	| index |
	index := (subjectClass allInstVarNames collect: [ :each | each asSymbol ])
		indexOf: instVarName asSymbol
		ifAbsent: [ self error: 'Inst var not found: ', instVarName printString ].
	^ self
		mapProperty: propertyName asString
		getter: [ :object | object instVarAt: index ]
		setter: [ :object :value | object instVarAt: index put: value ]

]

{ #category : 'convenience' }
SimdJSONObjectMapping >> mapInstVars [
	^ self mapInstVars: subjectClass instVarNames

]

{ #category : 'mapping' }
SimdJSONObjectMapping >> mapInstVars: instVarNames [
	^ instVarNames collect: [ :each | self mapInstVar: each ]

]

{ #category : 'mapping' }
SimdJSONObjectMapping >> mapProperty: propertyName getter: readBlock setter: writeBlock [
	| propertyMapping |
	propertyMapping := SimdJSONPropertyMapping new.
	propertyMapping
		propertyName: propertyName;
		getter: readBlock;
		setter: writeBlock.
	properties removeAllSuchThat: [ :each | each propertyName = propertyMapping propertyName ].
	properties addLast: propertyMapping.
	^ propertyMapping

]

{ #category : 'accessing' }
SimdJSONObjectMapping >> propertyNamed: propertyName ifAbsent: block [
	| symbolPropertyName |
	symbolPropertyName := propertyName asSymbol.
	^ properties detect: [ :each | each propertyName = symbolPropertyName ] ifNone: block

]

{ #category : 'parsing' }
SimdJSONObjectMapping >> readFrom: jsonReader [
	"NeoJSON's, except that the value of an unknown key is skipped, not read"

	| anObject |
	anObject := subjectClass new.
	allowNil ifTrue: [
		jsonReader parseConstantDo: [ :value |
			^ value ifNotNil: [ jsonReader error: 'Unexpected boolean constant' ] ] ].
	jsonReader parseMapKeysDo: [ :key |
		(self propertyNamed: key ifAbsent: [ nil ])
			ifNil: [ jsonReader skipValue ]
			ifNotNil: [ :mapping |
				mapping readObject: anObject from: jsonReader ] ].
	^ anObject

]

{ #category : 'accessing' }
SimdJSONObjectMapping >> subjectClass: smalltalkClass [
	subjectClass := smalltalkClass

]

{ #category : 'writing' }
SimdJSONObjectMapping >> writeObject: anObject on: jsonWriter [
	jsonWriter writeMapStreamingDo: [ :jsonMapWriter |
		properties do: [ :each | each writeObject: anObject on: jsonMapWriter ] ]

]
