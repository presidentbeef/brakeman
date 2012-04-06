module PostsHelper
  def author_of? post
    @current_user and post.user_id == @current_user.id
  end
end
