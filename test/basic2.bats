# Test Lingon against the simplest project possible.
# Covers: Building, Concatenating, Serving over http

# Before each spec
setup() {
  # cd to the basic test project
  CWD='test/basic2'
  cd $CWD
}

@test "basic project 2: can build" {
  # Remove existing build/
  if [ -d './build' ]; then
    rm -r ./build 2> /dev/null
  fi

  # Build project
  ./lingon.js build

  # Check that correct output files exist
  [ -f 'build/js/vendor.js' ]
  [ -f 'build/css/vendor.css' ]
}

@test "basic project 2: can concatenate js files" {
  # Compare the built index.js file to a reference
  # Success if diff exited with status 0 

  diff build/js/vendor.js fixtures/vendor.js  
  [ $? -eq 0 ]
}

@test "basic project 2: less files with valid globs include self and globs" {
  diff build/matching_include.css fixtures/matching_include.css
  [ $? -eq 0 ]
}

@test "basic project 2: less files with empty globs still include self" {
  diff build/non_matching_include.css fixtures/non_matching_include.css
  [ $? -eq 0 ]
}

@test "basic project 2: can serve files over http" {
  # Remove existing tmp/
  if [ -d './tmp' ]; then
    rm -r ./tmp 2> /dev/null
  fi
  
  # Create tmp/
  mkdir ./tmp

  # Start the http server
  LINGON_JOB="./lingon.js server -p 4567"
  eval ${LINGON_JOB} > /dev/null &
  LINGON_JOB_PID=`ps ax | grep -e "${LINGON_JOB}" | grep -v grep | awk '{print $1}'`

  # Wait a while
  sleep 2

  # Create new file after initial build
  cp source/js/vendor.js source/js/vendor_copy.js

  # Get some files
  server="http://localhost:4567"
  download="curl --silent -o"
  
  ${download} tmp/vendor.js $server/js/vendor.js
  ${download} tmp/vendor_copy.js $server/js/vendor_copy.js
  ${download} tmp/vendor.css $server/css/vendor.css

  # Terminate server
  kill $LINGON_JOB_PID

  # Did we get everything?
  diff tmp/vendor.js build/js/vendor.js
  [ $? -eq 0 ]

  diff tmp/vendor_copy.js build/js/vendor_copy.js
  [ $? -eq 0 ]

  diff tmp/vendor.css build/css/vendor.css
  [ $? -eq 0 ]

  # Remove late created source file
  rm source/js/vendor_copy.js
}