Class {
	#name : 'SimdJSONTestStream',
	#superclass : 'Object',
	#instVars : [
		'stream',
		'closed'
	],
	#category : 'SimdJSON-Tests-Support',
	#package : 'SimdJSON-Tests',
	#tag : 'Support'
}

{ #category : 'instance creation' }
SimdJSONTestStream class >> on: aString [
	"A character stream that is not a ReadStream, with the protocol of NeoJSONMockStream:
	 the reader reads it to its end"

	^ self new setStream: aString readStream
]

{ #category : 'testing' }
SimdJSONTestStream >> atEnd [

	^ stream atEnd
]

{ #category : 'initialize-release' }
SimdJSONTestStream >> close [

	closed := true
]

{ #category : 'accessing' }
SimdJSONTestStream >> collectionSpecies [

	^ String
]

{ #category : 'testing' }
SimdJSONTestStream >> isClosed [

	^ closed
]

{ #category : 'accessing' }
SimdJSONTestStream >> next [

	^ stream next
]

{ #category : 'accessing' }
SimdJSONTestStream >> peek [

	^ stream peek
]

{ #category : 'accessing' }
SimdJSONTestStream >> peekFor: aCharacter [

	^ stream peekFor: aCharacter
]

{ #category : 'initialization' }
SimdJSONTestStream >> setStream: aReadStream [

	stream := aReadStream.
	closed := false
]
