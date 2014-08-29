# Test Lingon against the simplest project possible.
# Covers: Custom processors, alternate processor syntax

# Before each spec
setup() {
  # cd to the processors test project
  CWD='tests/system/processors'
  cd $CWD
}

@test "processors project: can build custom processors" {
  # Remove existing build/
  if [ -d './build' ]; then
    rm -r ./build 2> /dev/null
  fi

  # Build project
  ./lingon.js build

  # Check that correct output files exist
  [ -f 'build/index.simplesyntax' ]
  [ -f 'build/matching.simplesyntax' ]
  [ -f 'build/index.simplealias' ]
  [ -f 'build/matching.simplealias' ]
  [ -f 'build/index.alternativesyntax' ]
  [ -f 'build/index.multiplesyntax' ]
  [ -f 'build/index.orderedsyntax' ]
}

@test "processors project: custom processors produce correct output" {
  diff build/index.simplesyntax fixtures/index.simplesyntax
  [ $? -eq 0 ]

  diff build/matching.simplesyntax fixtures/matching.simplesyntax
  [ $? -eq 0 ]

  diff build/index.simplealias fixtures/index.simplealias
  [ $? -eq 0 ]

  diff build/matching.simplealias fixtures/matching.simplealias
  [ $? -eq 0 ]

  diff build/index.alternativesyntax fixtures/index.alternativesyntax
  [ $? -eq 0 ]

  diff build/index.multiplesyntax fixtures/index.multiplesyntax
  [ $? -eq 0 ]

  diff build/index.orderedsyntax fixtures/index.orderedsyntax
  [ $? -eq 0 ]

}
