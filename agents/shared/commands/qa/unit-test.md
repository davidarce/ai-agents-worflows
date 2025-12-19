---
allowed-tools: Read, Edit, Write, Bash(mvn :*)
argument-hint: <className>
description: Generate, Add, Improve or Adapt unit tests (UT) for a Java class following project patterns.
---

## Goal

Generate, Add, Improve or Adapt unit tests for the given Java class following project patterns and best practices.

## Implementation Standards

- Mocking Strategy
  **Prefer real values** over `any()` matchers when possible:
- ✅ `given(repo.findById(specificId)).willReturn(...)`
- ⚠️ `given(repo.findById(any())).willReturn(...)` (only when testing flexible behavior)

**Mock all external dependencies**: repositories, domain services, external clients
**Don't mock**: value objects, domain entities, DTOs under test

**Test Data Generation**
- Mother classes are located in the `domain` module under `src/test/java/.../mother/`
  Use Mother pattern exclusively for test data:
- `EntityMother.create().withField(value).build()`
- `EntityMother.createList(count)`
- Helper methods return Mother-generated data for clarity

Assertions and Verifications
  **AssertJ fluent style**:
- `assertThat(result.field()).isEqualTo(expected)`
- `assertThat(list).hasSize(3).allMatch(item -> item.isValid())`

**BDDMockito verifications**:
- `then(dependency).should().method(specificValue)`
- `then(dependency).should(times(2)).method(any())`
- `then(dependency).should(never()).method(any())`

**ArgumentCaptors** for complex object verification:
`then(repository).should().save(entityCaptor.capture());`
`assertThat(entityCaptor.getValue().status()).isEqualTo(ACTIVE);`

## Steps to Follow

1. **Analyze class logic received from $ARGUMENTS:**
   - Understand class purpose and methods
   - Identify dependencies and collaborators with deep details
   - Identify main scenarios and flows

2. **Create comprehensive test scenarios:**
   - Happy path tests with expected results verification
   - Edge cases and error handling scenarios
   - Parameter validation tests if applicable
   - Multiple test methods with clear naming (should[DoSomething]When[Condition])

3. **Run and validate test:**
   - Ensure the clas test compiles
   - **ALWAYS** Ensure all tests pass successfully
   - To run tests in the specific module, use:
     ```bash
     mvn test -pl <module-name> -Dtest=<TestClassName>
     ``` 

4. **Verification:** This is mandatory!
   - Use the subagent `qa-unit-test-verifier` to ensure compliance with project standards.