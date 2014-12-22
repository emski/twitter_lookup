class Controller
	
	constructor: ($scope, $location, gitService) ->
		$scope.user = gitService.user
		$scope.repos = gitService.repos


angular.module('app').controller 'userReposController', ['$scope', '$location', 'gitService', Controller]
