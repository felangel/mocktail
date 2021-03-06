library mocktail;

export 'src/fake.dart';
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

        // -- verification
        verify,
        verifyInOrder,
        verifyNever,
        verifyNoMoreInteractions,
        verifyZeroInteractions,
        VerificationResult,
        ListOfVerificationResult,

        // -- misc
        throwOnMissingStub,
        clearInteractions,
        reset,
        resetMocktailState,
        logInvocations,
        untilCalled,
        MissingStubError;
