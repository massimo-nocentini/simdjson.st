Extension { #name : 'ByteString' }

{ #category : '*SimdJSON' }
ByteString >> isSimdJSONPlain [
	"Exactly a ByteString"

	^ self class == ByteString
]

{ #category : '*SimdJSON' }
ByteString >> simdJSONUTF8Size [
	"The bytes of my UTF-8, as primitiveWrite counts its output: my size, and a byte more for
	each character above 127.  A primitive finds each of them, skipping the ASCII before it;
	once 64 are found, at more than one in 8 characters, a loop counts the rest, cheaper
	than a call each"

	| size bytes index |
	size := self size.
	bytes := size.
	index := 0.
	[ (index := ByteString findFirstInString: self inSet: NonAsciiMap startingAt: index + 1) > 0 ]
		whileTrue: [
			bytes := bytes + 1.
			(bytes - size >= 64 and: [ (bytes - size) * 8 > index ]) ifTrue: [
				index + 1 to: size do: [ :each | (self basicAt: each) > 127 ifTrue: [ bytes := bytes + 1 ] ].
				^ bytes ] ].
	^ bytes
]
