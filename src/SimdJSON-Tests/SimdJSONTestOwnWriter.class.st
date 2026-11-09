Class {
	#name : 'SimdJSONTestOwnWriter',
	#superclass : 'Object',
	#instVars : [
		'value'
	],
	#category : 'SimdJSON-Tests-Support',
	#package : 'SimdJSON-Tests',
	#tag : 'Support'
}

{ #category : 'writing' }
SimdJSONTestOwnWriter >> neoJsonOn: aWriter [
	"NeoJSON's protocol of an object that writes itself"

	aWriter writeMapStreamingDo: [ :map | map writeKey: 'own' value: value ]
]

{ #category : 'accessing' }
SimdJSONTestOwnWriter >> value: anObject [

	value := anObject
]
