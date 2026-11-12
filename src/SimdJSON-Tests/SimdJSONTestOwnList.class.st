"
An OrderedCollection that writes itself with neoJsonOn:, which primitiveWrite leaves to the image: not exactly an OrderedCollection.
"
Class {
	#name : 'SimdJSONTestOwnList',
	#superclass : 'OrderedCollection',
	#category : 'SimdJSON-Tests-Support',
	#package : 'SimdJSON-Tests',
	#tag : 'Support'
}

{ #category : 'writing' }
SimdJSONTestOwnList >> neoJsonOn: aWriter [
	"NeoJSON's protocol of an object that writes itself: a map, not a list"

	aWriter writeMapStreamingDo: [ :map | map writeKey: 'own' value: self asArray ]
]
