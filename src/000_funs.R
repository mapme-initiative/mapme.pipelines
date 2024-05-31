order_parallel <- function(x, ncores = 4, bboxs = NULL) {
  stopifnot(is.numeric(ncores) || length(ncores) == 1)
  stopifnot(is.null(bboxs) || is.numeric(bboxs))
  if (is.null(bboxs)) {
    bboxs <- sapply(1:nrow(x), function(i) st_area(st_as_sfc(st_bbox(x[i,]))))
  }
  bboxs_ordered <- order(bboxs, decreasing = TRUE)
  index <- rep(1:ncores, round(length(bboxs) / ncores))[1:length(bboxs)]
  index <- order(index)
  x[bboxs_ordered[index], ]
}
