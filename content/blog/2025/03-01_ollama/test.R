

my_function <- function(x, y){
  if(!is.numeric(y)){
    stop(paste(
      "input y needs to be numeric, not class",
      class(y))
    )
  }
  x + y
}
