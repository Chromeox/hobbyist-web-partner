'use client';

import React, { useState, useCallback, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  X,
  Camera,
  Video,
  Upload,
  Trash2,
  Tag,
  Eye,
  EyeOff,
  CheckCircle,
  AlertCircle,
  ImageIcon,
  Play,
  Star
} from 'lucide-react';
import RatingStars from './RatingStars';

interface ReviewModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (reviewData: ReviewSubmissionData) => Promise<void>;
  classId: string;
  className?: string;
  instructorName?: string;
  verifiedBooking?: boolean;
  existingReview?: ReviewData | null;
}

export interface ReviewData {
  id: string;
  rating: number;
  reviewText: string;
  isAnonymous: boolean;
  tags: string[];
  media: MediaFile[];
  verifiedBooking: boolean;
}

export interface ReviewSubmissionData {
  rating: number;
  reviewText: string;
  isAnonymous: boolean;
  tags: string[];
  mediaFiles: File[];
  classId: string;
}

export interface MediaFile {
  id: string;
  type: 'photo' | 'video';
  url: string;
  thumbnailUrl?: string;
  file?: File;
  name: string;
  size: number;
}

const PREDEFINED_TAGS = [
  'Great instructor',
  'Clean facility',
  'Good equipment',
  'Challenging workout',
  'Beginner friendly',
  'Great music',
  'Small class size',
  'Excellent teaching',
  'Well organized',
  'Fun atmosphere',
  'Good value',
  'Professional staff'
];

const MAX_FILES = 5;
const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
const ACCEPTED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const ACCEPTED_VIDEO_TYPES = ['video/mp4', 'video/webm', 'video/quicktime'];

const ReviewModal: React.FC<ReviewModalProps> = ({
  isOpen,
  onClose,
  onSubmit,
  classId,
  className = '',
  instructorName,
  verifiedBooking = false,
  existingReview = null
}) => {
  const [rating, setRating] = useState(existingReview?.rating || 0);
  const [reviewText, setReviewText] = useState(existingReview?.reviewText || '');
  const [isAnonymous, setIsAnonymous] = useState(existingReview?.isAnonymous || false);
  const [selectedTags, setSelectedTags] = useState<string[]>(existingReview?.tags || []);
  const [customTag, setCustomTag] = useState('');
  const [mediaFiles, setMediaFiles] = useState<MediaFile[]>(existingReview?.media || []);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  const fileInputRef = useRef<HTMLInputElement>(null);
  const characterLimit = 1000;

  // Reset form when modal opens/closes
  React.useEffect(() => {
    if (isOpen && !existingReview) {
      setRating(0);
      setReviewText('');
      setIsAnonymous(false);
      setSelectedTags([]);
      setCustomTag('');
      setMediaFiles([]);
      setErrors({});
    }
  }, [isOpen, existingReview]);

  // Handle file upload
  const handleFileUpload = useCallback(async (files: FileList) => {
    const newFiles: MediaFile[] = [];
    const newErrors: Record<string, string> = {};

    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      
      // Check file count limit
      if (mediaFiles.length + newFiles.length >= MAX_FILES) {
        newErrors.media = `Maximum ${MAX_FILES} files allowed`;
        break;
      }

      // Check file size
      if (file.size > MAX_FILE_SIZE) {
        newErrors.media = `File "${file.name}" is too large. Maximum size is 10MB.`;
        continue;
      }

      // Check file type
      const isImage = ACCEPTED_IMAGE_TYPES.includes(file.type);
      const isVideo = ACCEPTED_VIDEO_TYPES.includes(file.type);
      
      if (!isImage && !isVideo) {
        newErrors.media = `File "${file.name}" is not supported. Please use JPG, PNG, WebP, MP4, WebM, or QuickTime files.`;
        continue;
      }

      // Create preview URL
      const url = URL.createObjectURL(file);
      
      const mediaFile: MediaFile = {
        id: `temp-${Date.now()}-${i}`,
        type: isImage ? 'photo' : 'video',
        url,
        file,
        name: file.name,
        size: file.size
      };

      // Generate thumbnail for videos
      if (isVideo) {
        try {
          const thumbnailUrl = await generateVideoThumbnail(file);
          mediaFile.thumbnailUrl = thumbnailUrl;
        } catch (error) {
          console.warn('Could not generate video thumbnail:', error);
        }
      }

      newFiles.push(mediaFile);
    }

    setMediaFiles(prev => [...prev, ...newFiles]);
    setErrors(prev => ({ ...prev, ...newErrors }));
  }, [mediaFiles]);

  // Generate video thumbnail
  const generateVideoThumbnail = (videoFile: File): Promise<string> => {
    return new Promise((resolve, reject) => {
      const video = document.createElement('video');
      const canvas = document.createElement('canvas');
      const ctx = canvas.getContext('2d');

      video.addEventListener('loadeddata', () => {
        canvas.width = video.videoWidth;
        canvas.height = video.videoHeight;
        
        video.currentTime = 1; // Seek to 1 second
      });

      video.addEventListener('seeked', () => {
        if (ctx) {
          ctx.drawImage(video, 0, 0);
          const thumbnailUrl = canvas.toDataURL('image/jpeg', 0.7);
          resolve(thumbnailUrl);
        } else {
          reject(new Error('Could not get canvas context'));
        }
      });

      video.addEventListener('error', reject);
      video.src = URL.createObjectURL(videoFile);
    });
  };

  // Remove media file
  const removeMediaFile = useCallback((fileId: string) => {
    setMediaFiles(prev => {
      const updated = prev.filter(file => file.id !== fileId);
      // Clean up object URLs
      const removedFile = prev.find(file => file.id === fileId);
      if (removedFile?.url.startsWith('blob:')) {
        URL.revokeObjectURL(removedFile.url);
      }
      if (removedFile?.thumbnailUrl?.startsWith('blob:')) {
        URL.revokeObjectURL(removedFile.thumbnailUrl);
      }
      return updated;
    });
  }, []);

  // Handle tag selection
  const toggleTag = useCallback((tag: string) => {
    setSelectedTags(prev => 
      prev.includes(tag) 
        ? prev.filter(t => t !== tag)
        : [...prev, tag]
    );
  }, []);

  // Add custom tag
  const addCustomTag = useCallback(() => {
    const tag = customTag.trim();
    if (tag && !selectedTags.includes(tag)) {
      setSelectedTags(prev => [...prev, tag]);
      setCustomTag('');
    }
  }, [customTag, selectedTags]);

  // Form validation
  const validateForm = useCallback((): boolean => {
    const newErrors: Record<string, string> = {};

    if (rating === 0) {
      newErrors.rating = 'Please select a rating';
    }

    if (reviewText.trim().length < 10) {
      newErrors.reviewText = 'Review must be at least 10 characters long';
    }

    if (reviewText.length > characterLimit) {
      newErrors.reviewText = `Review must not exceed ${characterLimit} characters`;
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }, [rating, reviewText, characterLimit]);

  // Handle form submission
  const handleSubmit = useCallback(async () => {
    if (!validateForm()) return;

    setIsSubmitting(true);
    try {
      const submissionData: ReviewSubmissionData = {
        rating,
        reviewText: reviewText.trim(),
        isAnonymous,
        tags: selectedTags,
        mediaFiles: mediaFiles.map(f => f.file!).filter(Boolean),
        classId
      };

      await onSubmit(submissionData);
      onClose();
    } catch (error) {
      setErrors({ submit: 'Failed to submit review. Please try again.' });
    } finally {
      setIsSubmitting(false);
    }
  }, [validateForm, rating, reviewText, isAnonymous, selectedTags, mediaFiles, classId, onSubmit, onClose]);

  // Clean up object URLs on unmount
  React.useEffect(() => {
    return () => {
      mediaFiles.forEach(file => {
        if (file.url.startsWith('blob:')) {
          URL.revokeObjectURL(file.url);
        }
        if (file.thumbnailUrl?.startsWith('blob:')) {
          URL.revokeObjectURL(file.thumbnailUrl);
        }
      });
    };
  }, [mediaFiles]);

  if (!isOpen) return null;

  return (
    <AnimatePresence>
      <motion.div
        className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={onClose}
      >
        <motion.div
          className={`bg-white dark:bg-gray-800 rounded-xl shadow-2xl w-full max-w-2xl max-h-[90vh] overflow-hidden ${className}`}
          initial={{ scale: 0.95, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          exit={{ scale: 0.95, opacity: 0 }}
          onClick={e => e.stopPropagation()}
        >
          {/* Header */}
          <div className="flex items-center justify-between p-6 border-b border-gray-200 dark:border-gray-700">
            <div>
              <h2 className="text-2xl font-bold text-gray-900 dark:text-white">
                {existingReview ? 'Edit Review' : 'Write a Review'}
              </h2>
              {instructorName && (
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  For class with {instructorName}
                </p>
              )}
            </div>
            <button
              onClick={onClose}
              className="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
              disabled={isSubmitting}
            >
              <X size={24} />
            </button>
          </div>

          {/* Content */}
          <div className="p-6 overflow-y-auto max-h-[calc(90vh-140px)]">
            {/* Verified Booking Badge */}
            {verifiedBooking && (
              <div className="flex items-center gap-2 mb-6 p-3 bg-green-50 dark:bg-green-900/20 rounded-lg">
                <CheckCircle size={20} className="text-green-600 dark:text-green-400" />
                <span className="text-sm text-green-800 dark:text-green-300 font-medium">
                  Verified booking - This review is from a confirmed class attendance
                </span>
              </div>
            )}

            {/* Rating Section */}
            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
                Overall Rating *
              </label>
              <div className="flex items-center gap-4">
                <RatingStars
                  rating={rating}
                  onRatingChange={setRating}
                  interactive
                  size="lg"
                  showLabel
                />
              </div>
              {errors.rating && (
                <p className="mt-1 text-sm text-red-600 dark:text-red-400">
                  {errors.rating}
                </p>
              )}
            </div>

            {/* Review Text */}
            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
                Write Your Review *
              </label>
              <textarea
                value={reviewText}
                onChange={(e) => setReviewText(e.target.value)}
                placeholder="Share your experience with this class..."
                rows={6}
                className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none dark:bg-gray-700 dark:border-gray-600 dark:text-white ${
                  errors.reviewText ? 'border-red-500' : 'border-gray-300'
                }`}
                disabled={isSubmitting}
              />
              <div className="flex justify-between items-center mt-2">
                {errors.reviewText ? (
                  <p className="text-sm text-red-600 dark:text-red-400">
                    {errors.reviewText}
                  </p>
                ) : (
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    Minimum 10 characters required
                  </p>
                )}
                <p className={`text-sm ${
                  reviewText.length > characterLimit 
                    ? 'text-red-600 dark:text-red-400' 
                    : 'text-gray-500 dark:text-gray-400'
                }`}>
                  {reviewText.length}/{characterLimit}
                </p>
              </div>
            </div>

            {/* Tags Section */}
            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
                Tags (Optional)
              </label>
              <div className="flex flex-wrap gap-2 mb-3">
                {PREDEFINED_TAGS.map(tag => (
                  <button
                    key={tag}
                    type="button"
                    onClick={() => toggleTag(tag)}
                    className={`px-3 py-1 text-sm rounded-full border transition-colors ${
                      selectedTags.includes(tag)
                        ? 'bg-blue-100 border-blue-500 text-blue-700 dark:bg-blue-900/30 dark:border-blue-400 dark:text-blue-300'
                        : 'bg-gray-100 border-gray-300 text-gray-700 hover:bg-gray-200 dark:bg-gray-700 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-600'
                    }`}
                    disabled={isSubmitting}
                  >
                    {tag}
                  </button>
                ))}
              </div>
              <div className="flex gap-2">
                <input
                  type="text"
                  value={customTag}
                  onChange={(e) => setCustomTag(e.target.value)}
                  placeholder="Add custom tag..."
                  className="flex-1 px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                  disabled={isSubmitting}
                  onKeyPress={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault();
                      addCustomTag();
                    }
                  }}
                />
                <button
                  type="button"
                  onClick={addCustomTag}
                  className="px-4 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50"
                  disabled={!customTag.trim() || isSubmitting}
                >
                  <Tag size={16} />
                </button>
              </div>
            </div>

            {/* Media Upload */}
            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
                Photos & Videos (Optional)
              </label>
              
              {/* Upload Button */}
              <div className="mb-4">
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  className="flex items-center gap-2 px-4 py-2 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors disabled:opacity-50"
                  disabled={mediaFiles.length >= MAX_FILES || isSubmitting}
                >
                  <Upload size={20} />
                  <span>Upload Files ({mediaFiles.length}/{MAX_FILES})</span>
                </button>
                <input
                  ref={fileInputRef}
                  type="file"
                  multiple
                  accept={[...ACCEPTED_IMAGE_TYPES, ...ACCEPTED_VIDEO_TYPES].join(',')}
                  onChange={(e) => e.target.files && handleFileUpload(e.target.files)}
                  className="hidden"
                />
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-2">
                  Max {MAX_FILES} files, 10MB each. JPG, PNG, WebP, MP4, WebM, QuickTime supported.
                </p>
              </div>

              {/* Media Preview */}
              {mediaFiles.length > 0 && (
                <div className="grid grid-cols-3 gap-3">
                  {mediaFiles.map(file => (
                    <div key={file.id} className="relative group">
                      <div className="aspect-square bg-gray-100 dark:bg-gray-700 rounded-lg overflow-hidden">
                        {file.type === 'photo' ? (
                          <img
                            src={file.url}
                            alt={file.name}
                            className="w-full h-full object-cover"
                          />
                        ) : (
                          <div className="relative w-full h-full">
                            {file.thumbnailUrl ? (
                              <img
                                src={file.thumbnailUrl}
                                alt={file.name}
                                className="w-full h-full object-cover"
                              />
                            ) : (
                              <div className="flex items-center justify-center w-full h-full">
                                <Video size={32} className="text-gray-400" />
                              </div>
                            )}
                            <div className="absolute inset-0 flex items-center justify-center bg-black bg-opacity-20">
                              <Play size={24} className="text-white" />
                            </div>
                          </div>
                        )}
                      </div>
                      <button
                        type="button"
                        onClick={() => removeMediaFile(file.id)}
                        className="absolute -top-2 -right-2 p-1 bg-red-500 text-white rounded-full hover:bg-red-600 transition-colors opacity-0 group-hover:opacity-100"
                        disabled={isSubmitting}
                      >
                        <Trash2 size={12} />
                      </button>
                    </div>
                  ))}
                </div>
              )}

              {errors.media && (
                <p className="mt-2 text-sm text-red-600 dark:text-red-400">
                  {errors.media}
                </p>
              )}
            </div>

            {/* Anonymous Option */}
            <div className="mb-6">
              <label className="flex items-center gap-3 cursor-pointer">
                <input
                  type="checkbox"
                  checked={isAnonymous}
                  onChange={(e) => setIsAnonymous(e.target.checked)}
                  className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                  disabled={isSubmitting}
                />
                <div className="flex items-center gap-2">
                  {isAnonymous ? <EyeOff size={16} /> : <Eye size={16} />}
                  <span className="text-sm text-gray-700 dark:text-gray-300">
                    Post anonymously
                  </span>
                </div>
              </label>
              <p className="text-xs text-gray-500 dark:text-gray-400 ml-7 mt-1">
                Your name will not be shown with this review
              </p>
            </div>

            {/* Submit Error */}
            {errors.submit && (
              <div className="mb-4 p-3 bg-red-50 dark:bg-red-900/20 rounded-lg flex items-center gap-2">
                <AlertCircle size={20} className="text-red-600 dark:text-red-400" />
                <p className="text-sm text-red-800 dark:text-red-300">
                  {errors.submit}
                </p>
              </div>
            )}
          </div>

          {/* Footer */}
          <div className="flex items-center justify-end gap-3 p-6 border-t border-gray-200 dark:border-gray-700">
            <button
              onClick={onClose}
              className="px-6 py-2 text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 transition-colors"
              disabled={isSubmitting}
            >
              Cancel
            </button>
            <button
              onClick={handleSubmit}
              disabled={isSubmitting || rating === 0}
              className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
            >
              {isSubmitting ? (
                <>
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                  Submitting...
                </>
              ) : (
                <>
                  <Star size={16} />
                  {existingReview ? 'Update Review' : 'Submit Review'}
                </>
              )}
            </button>
          </div>
        </motion.div>
      </motion.div>
    </AnimatePresence>
  );
};

export default ReviewModal;