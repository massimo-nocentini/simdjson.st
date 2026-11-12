"
SimdJSON-FFI-Tests - the SUnit tests of the package SimdJSON-FFI

They need libSimdJSONFFI, and are skipped without it; with the plugin in the VM, they hide it (the test hook #pluginMissing), so that SimdJSONReader and SimdJSONWriter go through SimdJSONLibrary.

	SimdJSONFFIReaderTests   the tests of SimdJSONReaderTests, through the library; the
	                         helpers of the primitive call the library
	SimdJSONFFIMappingTests  the tests of SimdJSONMappingTests, through the library
	SimdJSONFFIWriterTests   the tests of SimdJSONWriterTests, through the library
	SimdJSONFFITests         the library, the decoder and the encoder: the tags of the
	                         tapes, what sj_ffi_take and sj_ffi_take_output copy,
	                         tickets, number texts, sources, WideStrings, holes (the
	                         instances of subclasses of the classes primitiveWrite
	                         knows among them), culprits and their numbering, the
	                         fallback, and the same values and texts as the plugin's
	                         when the VM has it
"
Class {
	#name : 'ManifestSimdJSONFFITests',
	#superclass : 'PackageManifest',
	#category : 'SimdJSON-FFI-Tests-Manifest',
	#package : 'SimdJSON-FFI-Tests',
	#tag : 'Manifest'
}
