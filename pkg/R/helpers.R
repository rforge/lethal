################################################################################

## (non-exported) helper functions

## for condidence intervals of the fitted splines
get_tval <- function(object, alpha = 0.05) {
    residual.df <- length(object$y) - sum(object$edf)
    tVal <- qt(1 - (alpha/2), residual.df)
    tVal
}


################################################################################

## helper function to create new data sets for prediction and compuation of LD
## values

make_newdata <- function(object, group = NULL) {

    if (!is.null(group) && length(group) != 1)
        stop("group must be an integer or a character string")

    ## extract info from LGmodel object
    variables <- object$variables

    ## extract data from fitted model
    newdata <- object$data

    ## get indices for variables
    idx <- !sapply(variables, is.null)
    terms <- lapply(variables[idx], function(x) grep(x, names(newdata)))
    terms <- lapply(terms, function(i) names(newdata)[i])

    ## get doses
    dose <- newdata[, terms$dose]

    ## set grid for dose
    dose <- seq(min(dose), max(dose), by = 1)
    if (length(dose) < 50)
        dose <- seq(min(dose), max(dose), length.out = 150)

    ## remove response and dose from data
    newdata[, terms$outcome] <- NULL
    newdata[, terms$dose] <- NULL

    ## subset data to group
    if (!is.null(variables$groups)) {
        if (is.null(group)) {
            warning("No group selected, prediction might be misleading")
        } else {
            if (is.numeric(group)) {
                group <- levels(newdata[, terms$groups])[group]
            } # else {  ## make sure that the group exists
              #   group <- levels(newdata[, terms$groups])
              # }
            newdata[, terms$groups] <- group
        }
    }
    newdata <- unique(newdata)
    newdata <- newdata[rep(1:nrow(newdata), each = length(dose)), , drop = FALSE]
    newdata[, variables$dose] <- dose
    return(newdata)
}

## compute differences between groups
ld.diff <- function(LD1, LD2) {
    if (is.list(LD1)) {
        RET <- lapply(1:length(LD1), function(i)
                      LD1[[i]][, 1, drop = FALSE] -
                      LD2[[i]][, 1, drop = FALSE])
        names(RET) <- names(LD1)
    } else {
        RET <- LD1[, 1, drop = FALSE] - LD2[, 1, drop = FALSE]
    }
    return(RET)
}

append.CI <- function(x, ci) {
    if (is.list(x)) {
        RET <- lapply(1:length(x), function(i)
                      cbind(x[[i]][, 1, drop = FALSE], ci[[i]]))
        names(RET) <- names(x)
    } else {
        RET <- cbind(x[, 1, drop = FALSE], ci)
    }
    return(RET)
}

combine.results <- function(CI, CI_Diff) {
    CI <- c(CI, CI_Diff)
    groupnms <- names(CI)
    if (is.list(CI[[1]])) {
        nms <- names(CI[[1]])
        ## rbind(CI[[1]][[i]], CI[[2]][[i]], ...) for all LD values (i)
        CI <- lapply(1:length(CI[[1]]), function(i)
                     do.call("rbind", lapply(CI, function(x) x[[i]])))
        ## add names of groups
        CI <- lapply(CI, function(mat) {
            rownames(mat) <- groupnms
            return(mat)})
        ## add names of LD values
        names(CI) <- nms
    } else {
        ## rbind(CI[[1]], CI[[2]], ...)
        CI <- do.call("rbind", CI)
        ## add names of groups
        rownames(CI) <- groupnms
    }
    return(CI)
}

