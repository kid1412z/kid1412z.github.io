<div class="copyright">
  {% set current = date(Date.now(), "YYYY") %}
  &copy; &nbsp; {% if theme.since and theme.since != current %} {{ theme.since }} - {% endif %}
  {{ current }}
  <span class="author"><a href="http://github.com/kid1412z">{{ config.author }}</a></span> &nbsp;|&nbsp; {{ __('footer.powered', '<a class="theme-link" href="http://hexo.io">Hexo</a>') }}
</div>

{% block footer %}{% endblock %}
