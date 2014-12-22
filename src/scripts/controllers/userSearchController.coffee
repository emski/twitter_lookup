class Controller
	
	constructor: ($scope, $location, gitService) ->
		$scope.isError = false
		$scope.errorMessage = ''
		$scope.users = gitService.users
		$scope.search = ''

		$scope.searchUsers = ()->
			resetError()

			# do some basic validation
			if !($scope.search.replace ' ','')
				setError 'Please enter user name to search'
				return

			gitService.searchUsers($scope.search).then (response)->
				$scope.users = gitService.users
			, (error)->
				setError 'There was a problem with calling external api'

		$scope.getUserRepos = (user)->
			# don't reload if the same user is already loaded
			if gitService.user and gitService.user.login is user.login 
				$location.url '/users/' + user.login + '/repos'
				return

			gitService.getUserRepos(user).then (response)->
				$location.url '/users/' + user.login + '/repos'

		
		setError = (message)->
			$scope.errorMessage = message
			$scope.isError = true
		
		resetError = ->
			$scope.errorMessage = ''
			$scope.isError = false



angular.module('app').controller 'userSearchController', ['$scope', '$location', 'gitService', Controller]