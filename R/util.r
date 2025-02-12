#' @export
decimalplaces <- function(x) {
  if ((x %% 1) != 0) {
    nchar(strsplit(sub('0+$', '', as.character(x)), ".", fixed=TRUE)[[1]][[2]])
  } else {
    return(0)
  }
}

#' @export
plot_param <- function(estimate, param, dates){
  colors = c('red', 'blue', 'green', 'cyan')
  dates <- as.factor(dates)
  ix <- estimate$t
  v_est <- estimate[, param]
  lvls <- levels(dates)
  plot(ix[dates == lvls[1]], v_est[dates == lvls[1]],
       col=colors[1], type='l',
       xlim = range(ix), ylim = range(v_est),
       main=param, xlab='index', ylab='estimate')
  for(i in 2:length(lvls)){
    lines(ix[dates == lvls[i]], v_est[dates == lvls[i]], col=colors[i])
  }
  if(param == 'alpha') legend('topleft', legend = lvls, col = colors, lty=rep(1, length(lvls)))
}

#' @export
latlong2state <- function(pointsDF) {
  # Prepare SpatialPolygons object with one SpatialPolygon
  # per state (plus DC, minus HI & AK)
  states <- map('state', fill=TRUE, col="transparent", plot=FALSE)
  IDs <- sapply(strsplit(states$names, ":"), function(x) x[1])
  states_sp <- map2SpatialPolygons(states, IDs=IDs,
                                   proj4string=CRS("+proj=longlat +datum=WGS84"))
  
  # Convert pointsDF to a SpatialPoints object 
  pointsSP <- SpatialPoints(pointsDF, 
                            proj4string=CRS("+proj=longlat +datum=WGS84"))
  
  # Use 'over' to get _indices_ of the Polygons object containing each point 
  indices <- over(pointsSP, states_sp)
  
  # Return the state names of the Polygons object containing each point
  stateNames <- sapply(states_sp@polygons, function(x) x@ID)
  stateNames[indices]
}

#' @export
rescale_round <- function(x, grid_size=100){
  if(!grid_size %in% c(20, 50, 100)){
    stop("grid_size must be one of 20, 50, 100")
  } else if(grid_size == 20){
    scaler <- .05
  } else if(grid_size == 50){
    scaler <- .02
  } else if(grid_size == 100){
    scaler <- .01
  }
  x <- round(scales::rescale(x, c(0, 1)), 2)
  x <- round(x/scaler)*scaler
  return(x)
}

#' @export
fix_hr <- function(df){
  df$hr[df$hr=="0800"] <- "0900" 
  df$hr[df$hr=="1000"] <- "1100" 
  df$hr[df$hr=="1900"] <- "2000" 
  df$hr[df$hr=="2200"] <- "2100" 
  return(df)
}

dot <- function(u, v){
  return((u%*%v)[1])
}

cos_angle_btwn <- function(u, v){
  dot_prod <- dot(u, v)
  mag_prod <- dot(u, u)*dot(v, v)
  cos_angle <- dot_prod/mag_prod
  return(cos_angle)
}

#' @export
project_scalar_direction <- function(theta, mag, v){
  u <- c(sin(pi*theta/180), cos(pi*theta/180))
  cos_angle <- cos_angle_btwn(u, v)
  scalar_proj <- mag*cos_angle
  return(scalar_proj)
}

#' @export 
wind_projection <- function(wind_direction, wind_speed, coord){
  if(wind_speed == '999' | wind_direction == '999'){
    return(0)
  } else {
    wind_direction <- as.numeric(wind_direction)
    wind_speed <- as.numeric(wind_speed)
    scalar_proj <- project_scalar_direction(
      theta=wind_direction,
      mag=wind_speed,
      v=coord
    )
    return(scalar_proj)
  }
}