import { 
  MapPin,  
  Star, 
  User,
  Eye,
  MessageCircle
} from 'lucide-react';
import { Post } from '../api';

interface PostCardProps {
  post: Post;
}

const PostCard = ({ post }: PostCardProps) => {
  const getUrgencyColor = (urgency: string) => {
    switch (urgency) {
      case 'now': return 'bg-red-100 text-red-800';
      case 'today': return 'bg-orange-100 text-orange-800';
      case 'tomorrow': return 'bg-yellow-100 text-yellow-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getUrgencyText = (urgency: string) => {
    switch (urgency) {
      case 'now': return 'Срочно';
      case 'today': return 'Сегодня';
      case 'tomorrow': return 'Завтра';
      case 'this_week': return 'На этой неделе';
      default: return 'Гибкий график';
    }
  };

  const getCategoryIcon = (category: string) => {
    switch (category) {
      case 'social': return '🎉';
      case 'job': return '💼';
      case 'task': return '🛠️';
      default: return '📝';
    }
  };

  const authorName = `${post.user.first_name} ${post.user.last_name}`;
  
  return (
    <div className="bg-white rounded-lg shadow-md p-4 hover:shadow-lg transition-shadow">
      <div className="flex justify-between items-start mb-2">
        <div className="flex items-center space-x-2">
          <span className="text-xl">{getCategoryIcon(post.category)}</span>
          <span className={`px-2 py-1 rounded-full text-xs font-medium ${getUrgencyColor(post.urgency)}`}>
            {getUrgencyText(post.urgency)}
          </span>
        </div>
      </div>
      
      <h3 className="font-semibold text-lg mb-2">{post.title}</h3>
      <p className="text-gray-600 text-sm mb-3 line-clamp-2">{post.description}</p>
      
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center space-x-1 text-sm text-gray-500">
          <MapPin size={14} />
          <span>{post.location}</span>
        </div>
        {post.price && (
          <span className="font-semibold text-green-600">
            {post.price.toLocaleString()} {post.currency || 'UZS'}
          </span>
        )}
      </div>
      
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <div className="w-8 h-8 bg-gray-300 rounded-full flex items-center justify-center">
            <User size={16} />
          </div>
          <div>
            <p className="text-sm font-medium">{authorName}</p>
            {post.user.rating && (
              <div className="flex items-center space-x-1">
                <Star size={12} className="text-yellow-400 fill-current" />
                <span className="text-xs text-gray-500">{post.user.rating}</span>
              </div>
            )}
          </div>
        </div>
        
        <div className="flex items-center space-x-2">
          <button className="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-50 rounded">
            <Eye size={16} />
          </button>
          <button className="p-2 text-gray-500 hover:text-green-600 hover:bg-green-50 rounded">
            <MessageCircle size={16} />
          </button>
        </div>
      </div>
    </div>
  );
};

export default PostCard;