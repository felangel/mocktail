/// A Dart mock library which simplifies mocking
/// with null safety support and no manual mocks or code generation.
library mocktail;

// ignore: deprecated_member_use
export 'package:test_api/fake.dart' show Fake;
export 'src/mocktail.dart'
    show
        Mock,

        // -- setting behaviour
        when,
        any,
        captureAny,
        Answer,
        Expectation,
        When,
        registerFallbackValue,

        // -- verification
        verify,
        verifyInOrder,
        verifyNever,
        verifyNoMoreInteractions,
        verifyZeroInteractions,
        VerificationResult,
        Verify,
        ListOfVerificationResult,

        // -- misc
        throwOnMissingStub,
        clearInteractions,
        reset,
        resetMocktailState,
        logInvocations,
        untilCalled,
        MissingStubError;
