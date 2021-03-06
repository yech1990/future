source("incl/start.R")

strategies <- supportedStrategies()

message("*** Nested futures ...")

for (strategy1 in strategies) {
  for (strategy2 in strategies) {
    message(sprintf("- plan(list('%s', '%s')) ...", strategy1, strategy2))
    plan(list(a = strategy1, b = strategy2))
    
    nested <- plan("list")
    stopifnot(
      length(nested) == 2L,
      all(names(nested) == c("a", "b")),
      inherits(plan(), strategy1)
    )

    x %<-% {
      a <- 1L

      ## IMPORTANT: Use future::plan() - not just plan() - otherwise
      ## we're exporting the plan() function including its local stack!
      plan_a <- unclass(future::plan("list"))
      nested_a <- nested[-1]

      stopifnot(
        length(nested_a) == 1L,
        length(plan_a) == 1L,
        inherits(plan_a[[1]], "future"),
        inherits(future::plan(), strategy2)
      )

      ## Attribute 'init' is modified at run time
      for (kk in seq_along(plan_a)) attr(plan_a[[kk]], "init") <- NULL
      for (kk in seq_along(nested_a)) attr(nested_a[[kk]], "init") <- NULL
      stopifnot(all.equal(plan_a, nested_a))

      y %<-% {
        b <- 2L
        
        ## IMPORTANT: Use future::plan() - not just plan() - otherwise
        ## we're exporting the plan() function including its local stack!
        plan_b <- future::plan("list")
        nested_b <- nested_a[-1]

        stopifnot(
          length(nested_b) == 0L,
          length(plan_b) == 1L,
          inherits(plan_b[[1]], "future"),
          inherits(future::plan(), getOption("future.default", "sequential"))
        )

        list(a = a, nested_a = nested_a, plan_a = plan_a,
             b = b, nested_b = nested_b, plan_b = plan_b)
      }
      y
    }

    str(x)

    stopifnot(
      length(x) == 3 * length(nested),
      all(names(x) == c("a", "nested_a", "plan_a",
                        "b", "nested_b", "plan_b")),

      x$a == 1L,
      length(x$nested_a) == 1L,
      is.list(x$plan_a),
      length(x$plan_a) == 1L,
      inherits(x$plan_a[[1]], "future"),

      x$b == 2L,
      length(x$nested_b) == 0L,
      is.list(x$plan_b),
      length(x$plan_b) == 1L,
      inherits(x$plan_b[[1]], "future"),
      inherits(x$plan_b[[1]], getOption("future.default", "sequential"))
    )

    ## Attribute 'init' is modified at run time
    for (kk in seq_along(x$plan_a)) attr(x$plan_a[[kk]], "init") <- NULL
    for (kk in seq_along(nested)) attr(nested[[kk]], "init") <- NULL
    stopifnot(all.equal(x$plan_a, nested[-1L]))

    rm(list = c("nested", "x"))

    message(sprintf("- plan(list('%s', '%s')) ... DONE", strategy1, strategy2))
  }
}

message("*** Nested futures ... DONE")

source("incl/end.R")
