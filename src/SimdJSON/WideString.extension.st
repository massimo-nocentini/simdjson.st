Extension { #name : 'WideString' }

{ #category : '*SimdJSON' }
WideString >> isSimdJSONPlain [
	"Exactly a WideString"

	^ self class == WideString
]

{ #category : '*SimdJSON' }
WideString >> simdJSONUTF8Size [
	"The bytes of my UTF-8, as primitiveWrite counts its output: a surrogate in 3"

	| bytes value |
	bytes := self size.
	1 to: self size do: [ :index |
		(value := self basicAt: index) > 127 ifTrue: [
			bytes := bytes + (value < 16r800
				ifTrue: [ 1 ]
				ifFalse: [ value < 16r10000 ifTrue: [ 2 ] ifFalse: [ 3 ] ]) ] ].
	^ bytes
]
