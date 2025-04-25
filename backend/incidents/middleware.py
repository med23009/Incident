class FixAuthorizationHeaderMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Fix for header Authorization not being passed in some environments
        if 'HTTP_AUTHORIZATION' not in request.META:
            auth = request.META.get('Authorization')
            if auth:
                request.META['HTTP_AUTHORIZATION'] = auth
        return self.get_response(request)
