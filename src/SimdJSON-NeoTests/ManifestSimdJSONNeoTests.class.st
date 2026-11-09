"
SimdJSON-NeoTests - SimdJSONReader against NeoJSON, in the package SimdJSON-NeoTests

NeoJSON with its tests (the groups core and tests of BaselineOfNeoJSON, which
BaselineOfSimdJSON loads for this package) is in the image, only to be compared with:
SimdJSONReader uses none of it.

	SimdJSONCompatTests        SimdJSONReader against NeoJSONReader, value for
	                           value: equal values with the same classes of
	                           numbers, strings and collections, the same
	                           position of the stream afterwards, and an error
	                           where NeoJSON has one.  What NeoJSON reads by its
	                           leniency (01, 1., a control character in a
	                           string), SimdJSONReader refuses with a
	                           SimdJSONParseError: no RFC 8259 input of
	                           validInputs may be refused.  The inputs are
	                           NeoJSON's semantics, random number tokens, and,
	                           when the environment has SJ_CORPUS (the
	                           jsonexamples directory of simdjson-data), the
	                           corpus and the jsonchecker files next to it.
	                           SimdJSONWriter against NeoJSONWriter, the same
	                           characters, plain, pretty and asciiOnly, on
	                           edge values (Fractions, Sets, OrderedDictionary,
	                           NeoJSONObject...) and on the corpus.
	SimdJSONNeoTestGenerator   subclasses NeoJSON's reader and writer tests as
	                           SJ<name>, with every method that reads or writes
	                           JSON recompiled to do it with SimdJSONReader and
	                           SimdJSONWriter, and to expect SimdJSON's errors; a test that only NeoJSON's
	                           leniency passes is skipped (lenientTests).  The
	                           postLoadDoIt of BaselineOfSimdJSON runs it
	                           (generateNeoTests), and puts the classes in the
	                           package SimdJSON-NeoTests-Generated
	                           (generatedPackageName), which the repository
	                           does not track.
	                           SimdJSONNeoTestGenerator report runs those
	                           classes and prints what passed.

Load it with the default group (or the group NeoTests) of BaselineOfSimdJSON, then:

	pharo --headless X.image --no-default-preferences test --fail-on-failure --fail-on-error SimdJSON-NeoTests
	pharo --headless X.image --no-default-preferences test --fail-on-failure --fail-on-error SimdJSON-NeoTests-Generated
	pharo --headless X.image --no-default-preferences eval 'SimdJSONNeoTestGenerator report'
"
Class {
	#name : 'ManifestSimdJSONNeoTests',
	#superclass : 'PackageManifest',
	#category : 'SimdJSON-NeoTests-Manifest',
	#package : 'SimdJSON-NeoTests',
	#tag : 'Manifest'
}
