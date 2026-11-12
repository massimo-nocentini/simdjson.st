Class {
	#name : 'SimdJSONFlatMap',
	#superclass : 'Object',
	#type : 'variable',
	#category : 'SimdJSON-Core',
	#package : 'SimdJSON',
	#tag : 'Core'
}

{ #category : 'testing' }
SimdJSONFlatMap >> isSimdJSONFlatMap [
	"Whether I am a map of the tree that SimdJSONReader materializes: I am"

	^ true

]

{ #category : 'converting' }
SimdJSONFlatMap >> simdJSONMaterializeWith: aReader map: aMapClass list: aListClass [
	"A map of aMapClass, my values materialized"

	^ aReader materializeMap: self map: aMapClass list: aListClass

]
