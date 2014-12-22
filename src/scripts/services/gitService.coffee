class Service
	constructor: ($http) ->

		userActivity = 'https://api.github.com/search/users'

		self = {}
		self.users = []
		self.user = null
		self.repos = []

		self.searchUsers = (searchStr)->
			promise = $http.get(userActivity, {params: q: searchStr}).then (results)->
				self.users = results.data.items
				results

		self.getUserRepos = (user)->
			self.user = user
			promise = $http.get(user.repos_url).then (results)->
				self.repos = results.data
				results
		
		return self

angular.module('app').service 'gitService', ['$http', Service]
