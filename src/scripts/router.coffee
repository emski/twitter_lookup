angular.module('app').config [
	'$routeProvider'
	($routeProvider) ->
		$routeProvider
		.when('/users/search',
			templateUrl: 'views/search.html'
			reloadOnSearch: false
		)
		.when('/users/:user_id/repos',
			templateUrl: 'views/repos.html'
			reloadOnSearch: false
		).otherwise(redirectTo: '/users/search')
]