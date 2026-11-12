"
A proxy that forwards each message it does not understand to the object it stands for (target), as the proxies of the image do: it is not an Object, and the VM answers its own class.
"
Class {
	#name : 'SimdJSONTestProxy',
	#superclass : 'ProtoObject',
	#instVars : [
		'target'
	],
	#category : 'SimdJSON-Tests-Support',
	#package : 'SimdJSON-Tests',
	#tag : 'Support'
}

{ #category : 'instance creation' }
SimdJSONTestProxy class >> on: anObject [

	^ self basicNew setTarget: anObject
]

{ #category : 'reflective operations' }
SimdJSONTestProxy >> doesNotUnderstand: aMessage [

	^ aMessage sendTo: target
]

{ #category : 'initialization' }
SimdJSONTestProxy >> setTarget: anObject [

	target := anObject
]
