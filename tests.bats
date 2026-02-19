#!/usr/bin/env bats

setup() {
  # runs before each test
#   export MY_APP="./my-app"
}

@test "displays help" {
    run lucli markspresso --help
  
    # Debug: print to terminal
    echo "status: $status" >&3
    echo "output: $output" >&3
    echo "lines[0]: ${lines[0]}" >&3

}
# @test "displays version" {
#   run $MY_APP --version
#   [ "$status" -eq 0 ]
#   [[ "$output" =~ "1.0" ]]
# }

# @test "fails on invalid input" {
#   run $MY_APP --invalid
#   [ "$status" -eq 1 ]
# }