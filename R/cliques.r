#' @export
eval_cliques <- function(grid_i, prior_grid, grid_size, directional=F){
  neighbors_prior <- eval_neighbors(prior_grid, grid_size) %>%
    mutate(eta = map_param_names(eta, directional)) %>%
    lazy_dt()
  
  if(!is.null(grid_i)){
    grid_i <- grid_i %>%
      select(-t) %>%
      mutate(eta = 'alpha')
    neighbors_prior <- neighbors_prior %>%
      as.data.frame() %>%
      rbind(grid_i) %>%
      lazy_dt()
  }
  
  grid <- empty_grid(grid_size) %>%
    lazy_dt() %>%
    left_join(neighbors_prior, by = c('latitude', 'longitude'))

  return(grid)
}

#' @export
grid_cliques <- function(grid_i, prior_grid, grid_size, directional=F){
  cliques <- eval_cliques(grid_i, prior_grid, grid_size, directional)
  
  grid <- cliques %>% 
    mutate(eta=coalesce(eta, 'none')) %>% 
    group_by(latitude, longitude, eta) %>% 
    summarise(n=n()) %>%
    as.data.frame() %>%
    spread(eta, n)
    
  if(!('alpha' %in% colnames(grid))){
    grid$alpha <- 0
  } 
  
  grid$event <- ifelse(grid$alpha == 0, 0, 1)
  
  grid[is.na(grid)] <- 0

  missing_params <- all_param_names(directional=directional)
  missing_params <- missing_params[!(missing_params %in% colnames(grid))]
  for (p in missing_params){
    grid[, p] <- 0
  }

  if (directional){
    nms <- all_param_names(drop_alpha=T, drop_beta=F, directional=directional)
    grid$alpha <- rowSums(grid[, nms]) 
  } else {
    grid$alpha <- grid$beta+grid$delta+grid$gamma+grid$kappa+grid$lambda
  }
  
  return(grid)
}