Class {
	#name : 'SimdJSONTestObject',
	#superclass : 'Object',
	#instVars : [
		'id',
		'name',
		'points',
		'stamp',
		'tags'
	],
	#category : 'SimdJSON-Tests-Support',
	#package : 'SimdJSON-Tests',
	#tag : 'Support'
}

{ #category : 'mapping' }
SimdJSONTestObject class >> neoJsonMapping: mapper [
	"The class-side hook that the mapper of NeoJSON, and its port, resolve"

	mapper for: self do: [ :mapping |
		mapping mapInstVars: #( #id #name ).
		(mapping mapInstVar: #points) valueSchema: #SimdJSONTestPoints.
		(mapping mapInstVar: #stamp to: 'created-at') valueSchema: #SimdJSONTestStamp.
		(mapping mapInstVar: #tags) valueSchema: #SimdJSONTestTags ].
	mapper for: #SimdJSONTestPoints customDo: [ :mapping | mapping listOfElementSchema: Point ].
	mapper mapAllInstVarsFor: Point.
	mapper for: #SimdJSONTestStamp customDo: [ :mapping | mapping decoder: [ :string | string asNumber ] ].
	mapper for: #SimdJSONTestTags customDo: [ :mapping | mapping listOfType: OrderedCollection ]
]

{ #category : 'accessing' }
SimdJSONTestObject >> id [

	^ id
]

{ #category : 'accessing' }
SimdJSONTestObject >> id: anObject [

	id := anObject
]

{ #category : 'accessing' }
SimdJSONTestObject >> name [

	^ name
]

{ #category : 'accessing' }
SimdJSONTestObject >> name: anObject [

	name := anObject
]

{ #category : 'accessing' }
SimdJSONTestObject >> points [

	^ points
]

{ #category : 'accessing' }
SimdJSONTestObject >> stamp [

	^ stamp
]

{ #category : 'accessing' }
SimdJSONTestObject >> tags [

	^ tags
]
