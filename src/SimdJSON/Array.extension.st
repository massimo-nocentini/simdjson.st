Extension { #name : 'Array' }

{ #category : '*SimdJSON' }
Array >> isSimdJSONPlain [
	"Exactly an Array"

	^ self class == Array
]

{ #category : '*SimdJSON' }
Array >> simdJSONMaterializeWith: aReader map: aMapClass list: aListClass [
	"A list of the tree: my children materialized in place, then copied once into aListClass"

	^ aReader materializeList: self map: aMapClass list: aListClass
]
