// File Upload & Media Handling Edge Function
// Handles file uploads, image processing, document management, and media optimization

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { createSupabaseClient, corsHeaders, createResponse, errorResponse, getUserId, validateBody, validateFileUpload, generateId, sanitizeInput } from '../_shared/utils.ts';

const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif'];
const ALLOWED_DOCUMENT_TYPES = ['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'];
const ALLOWED_VIDEO_TYPES = ['video/mp4', 'video/quicktime', 'video/x-msvideo'];

const MAX_IMAGE_SIZE_MB = 10;
const MAX_DOCUMENT_SIZE_MB = 25;
const MAX_VIDEO_SIZE_MB = 100;

serve(async (req: Request) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const method = req.method;
  const path = url.pathname.replace('/storage', '');

  try {
    const authHeader = req.headers.get('Authorization');

    // Route requests
    switch (method) {
      case 'POST':
        switch (path) {
          case '/upload':
            return handleFileUpload(req, authHeader);
          case '/upload-multiple':
            return handleMultipleFileUpload(req, authHeader);
          case '/upload-profile-image':
            return handleProfileImageUpload(req, authHeader);
          case '/upload-class-images':
            return handleClassImagesUpload(req, authHeader);
          case '/upload-certificate':
            return handleCertificateUpload(req, authHeader);
          case '/generate-signed-url':
            return handleGenerateSignedUrl(req, authHeader);
          case '/process-image':
            return handleImageProcessing(req, authHeader);
          default:
            return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
        }
      case 'GET':
        switch (path) {
          case '/user-files':
            return handleGetUserFiles(req, authHeader);
          case '/class-media':
            return handleGetClassMedia(req, authHeader);
          case '/download':
            return handleFileDownload(req, authHeader);
          default:
            if (path.startsWith('/file/')) {
              const fileId = path.replace('/file/', '');
              return handleGetFileInfo(req, authHeader, fileId);
            }
            return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
        }
      case 'DELETE':
        if (path.startsWith('/file/')) {
          const fileId = path.replace('/file/', '');
          return handleDeleteFile(req, authHeader, fileId);
        }
        return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
      case 'PUT':
        if (path.startsWith('/file/')) {
          const fileId = path.replace('/file/', '');
          return handleUpdateFile(req, authHeader, fileId);
        }
        return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
      default:
        return errorResponse('Method not allowed', 'METHOD_NOT_ALLOWED', 405);
    }
  } catch (error) {
    console.error('Storage function error:', error);
    return errorResponse(
      'Internal server error',
      'INTERNAL_ERROR',
      500,
      { message: error.message }
    );
  }
});

async function handleFileUpload(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const contentType = req.headers.get('content-type');
  if (!contentType?.includes('multipart/form-data')) {
    return errorResponse('Content-Type must be multipart/form-data', 'INVALID_CONTENT_TYPE', 400);
  }

  const supabase = createSupabaseClient();

  try {
    const formData = await req.formData();
    const file = formData.get('file') as File;
    const fileType = formData.get('type') as string || 'general'; // 'image', 'document', 'video', 'general'
    const isPublic = formData.get('public') === 'true';
    const description = formData.get('description') as string;
    const tags = formData.get('tags') as string;

    if (!file) {
      return errorResponse('No file provided', 'NO_FILE', 400);
    }

    // Validate file based on type
    let maxSizeMB = 10;
    let allowedTypes: string[] = [];

    switch (fileType) {
      case 'image':
        allowedTypes = ALLOWED_IMAGE_TYPES;
        maxSizeMB = MAX_IMAGE_SIZE_MB;
        break;
      case 'document':
        allowedTypes = ALLOWED_DOCUMENT_TYPES;
        maxSizeMB = MAX_DOCUMENT_SIZE_MB;
        break;
      case 'video':
        allowedTypes = ALLOWED_VIDEO_TYPES;
        maxSizeMB = MAX_VIDEO_SIZE_MB;
        break;
      default:
        allowedTypes = [...ALLOWED_IMAGE_TYPES, ...ALLOWED_DOCUMENT_TYPES];
        maxSizeMB = MAX_DOCUMENT_SIZE_MB;
    }

    const validation = validateFileUpload(file, maxSizeMB, allowedTypes);
    if (!validation.valid) {
      return errorResponse(validation.error!, 'FILE_VALIDATION_ERROR', 400);
    }

    // Generate unique filename
    const fileExtension = file.name.split('.').pop();
    const sanitizedName = sanitizeInput(file.name.replace(/\.[^/.]+$/, ''));
    const uniqueFileName = `${generateId('file')}_${sanitizedName}.${fileExtension}`;
    
    // Determine storage bucket and path
    const bucket = isPublic ? 'public-files' : 'private-files';
    const filePath = `${userId}/${fileType}/${uniqueFileName}`;

    // Upload to Supabase Storage
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from(bucket)
      .upload(filePath, file, {
        cacheControl: '3600',
        upsert: false,
        contentType: file.type,
      });

    if (uploadError) {
      return errorResponse(
        'Failed to upload file',
        'UPLOAD_ERROR',
        500,
        { supabase_error: uploadError }
      );
    }

    // Get public URL if applicable
    let publicUrl = null;
    if (isPublic) {
      const { data: urlData } = supabase.storage
        .from(bucket)
        .getPublicUrl(filePath);
      publicUrl = urlData.publicUrl;
    }

    // Save file metadata to database
    const fileMetadata = {
      id: generateId('file'),
      user_id: userId,
      original_name: file.name,
      file_name: uniqueFileName,
      file_path: filePath,
      file_type: fileType,
      mime_type: file.type,
      file_size: file.size,
      bucket,
      is_public: isPublic,
      public_url: publicUrl,
      description: description || null,
      tags: tags ? tags.split(',').map(t => t.trim()) : [],
      metadata: {
        upload_source: 'web',
        user_agent: req.headers.get('user-agent'),
      },
    };

    const { data: savedFile, error: saveError } = await supabase
      .from('user_files')
      .insert(fileMetadata)
      .select()
      .single();

    if (saveError) {
      // Cleanup uploaded file if database save fails
      await supabase.storage.from(bucket).remove([filePath]);
      return errorResponse(
        'Failed to save file metadata',
        'METADATA_ERROR',
        500,
        { supabase_error: saveError }
      );
    }

    // Process image if it's an image file
    if (fileType === 'image') {
      // Queue image processing job (thumbnails, optimization)
      await queueImageProcessing(savedFile.id, filePath, bucket);
    }

    return createResponse({
      file_id: savedFile.id,
      file_name: savedFile.file_name,
      original_name: savedFile.original_name,
      file_size: savedFile.file_size,
      file_size_formatted: formatFileSize(savedFile.file_size),
      mime_type: savedFile.mime_type,
      public_url: savedFile.public_url,
      upload_path: savedFile.file_path,
      is_public: savedFile.is_public,
      created_at: savedFile.created_at,
      message: 'File uploaded successfully',
    }, undefined, 201);
  } catch (error) {
    console.error('File upload error:', error);
    return errorResponse(
      'Failed to upload file',
      'UPLOAD_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleProfileImageUpload(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const supabase = createSupabaseClient();

  try {
    const formData = await req.formData();
    const file = formData.get('file') as File;

    if (!file) {
      return errorResponse('No file provided', 'NO_FILE', 400);
    }

    // Validate image file
    const validation = validateFileUpload(file, 5, ALLOWED_IMAGE_TYPES);
    if (!validation.valid) {
      return errorResponse(validation.error!, 'FILE_VALIDATION_ERROR', 400);
    }

    // Generate unique filename for profile image
    const fileExtension = file.name.split('.').pop();
    const profileImageName = `profile_${userId}_${Date.now()}.${fileExtension}`;
    const filePath = `profiles/${profileImageName}`;

    // Upload to public bucket
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from('avatars')
      .upload(filePath, file, {
        cacheControl: '3600',
        upsert: true, // Allow overwriting
        contentType: file.type,
      });

    if (uploadError) {
      return errorResponse(
        'Failed to upload profile image',
        'UPLOAD_ERROR',
        500,
        { supabase_error: uploadError }
      );
    }

    // Get public URL
    const { data: urlData } = supabase.storage
      .from('avatars')
      .getPublicUrl(filePath);

    // Update user profile with new avatar URL
    const { error: updateError } = await supabase
      .from('user_profiles')
      .update({
        avatar_url: urlData.publicUrl,
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', userId);

    if (updateError) {
      console.error('Failed to update profile with avatar URL:', updateError);
    }

    // Generate thumbnails
    await queueImageProcessing(userId, filePath, 'avatars', {
      generateThumbnails: true,
      sizes: [150, 300, 600],
      optimize: true,
    });

    return createResponse({
      avatar_url: urlData.publicUrl,
      file_path: filePath,
      file_size: file.size,
      file_size_formatted: formatFileSize(file.size),
      message: 'Profile image updated successfully',
    });
  } catch (error) {
    console.error('Profile image upload error:', error);
    return errorResponse(
      'Failed to upload profile image',
      'UPLOAD_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleClassImagesUpload(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const supabase = createSupabaseClient();

  try {
    const formData = await req.formData();
    const classId = formData.get('class_id') as string;
    const files = formData.getAll('files') as File[];
    const isPrimary = formData.getAll('is_primary') as string[];
    const altTexts = formData.getAll('alt_text') as string[];

    if (!classId) {
      return errorResponse('Class ID is required', 'MISSING_CLASS_ID', 400);
    }

    if (!files || files.length === 0) {
      return errorResponse('No files provided', 'NO_FILES', 400);
    }

    // Verify class ownership
    const { data: classData, error: classError } = await supabase
      .from('classes')
      .select(`
        id,
        instructor:instructor_profiles!inner(user_id)
      `)
      .eq('id', classId)
      .single();

    if (classError || classData.instructor.user_id !== userId) {
      return errorResponse('Class not found or access denied', 'FORBIDDEN', 403);
    }

    const uploadResults = [];
    const errors = [];

    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      const isMainImage = isPrimary[i] === 'true';
      const altText = altTexts[i] || '';

      try {
        // Validate each image
        const validation = validateFileUpload(file, MAX_IMAGE_SIZE_MB, ALLOWED_IMAGE_TYPES);
        if (!validation.valid) {
          errors.push({ file: file.name, error: validation.error });
          continue;
        }

        // Generate unique filename
        const fileExtension = file.name.split('.').pop();
        const imageFileName = `class_${classId}_${generateId('img')}.${fileExtension}`;
        const filePath = `classes/${classId}/${imageFileName}`;

        // Upload to public bucket
        const { data: uploadData, error: uploadError } = await supabase.storage
          .from('class-images')
          .upload(filePath, file, {
            cacheControl: '86400', // 24 hours
            upsert: false,
            contentType: file.type,
          });

        if (uploadError) {
          errors.push({ file: file.name, error: uploadError.message });
          continue;
        }

        // Get public URL
        const { data: urlData } = supabase.storage
          .from('class-images')
          .getPublicUrl(filePath);

        // Save image metadata
        const imageMetadata = {
          url: urlData.publicUrl,
          alt_text: altText,
          is_primary: isMainImage,
          order: i + 1,
          file_path: filePath,
          file_size: file.size,
          mime_type: file.type,
        };

        uploadResults.push({
          file_name: file.name,
          ...imageMetadata,
        });

        // Queue image processing for optimization and thumbnails
        await queueImageProcessing(classId, filePath, 'class-images', {
          generateThumbnails: true,
          sizes: [300, 600, 1200],
          optimize: true,
          watermark: false,
        });

      } catch (fileError) {
        errors.push({ file: file.name, error: fileError.message });
      }
    }

    // Update class with new images
    if (uploadResults.length > 0) {
      // Get existing images
      const { data: existingClass } = await supabase
        .from('classes')
        .select('images')
        .eq('id', classId)
        .single();

      const existingImages = existingClass?.images || [];
      const updatedImages = [...existingImages, ...uploadResults];

      // If there's a new primary image, update the existing ones
      const hasPrimaryImage = uploadResults.some(img => img.is_primary);
      if (hasPrimaryImage) {
        updatedImages.forEach((img, index) => {
          if (img.is_primary && !uploadResults.find(newImg => newImg.url === img.url)) {
            updatedImages[index] = { ...img, is_primary: false };
          }
        });
      }

      await supabase
        .from('classes')
        .update({
          images: updatedImages,
          updated_at: new Date().toISOString(),
        })
        .eq('id', classId);
    }

    return createResponse({
      class_id: classId,
      uploaded_images: uploadResults,
      upload_count: uploadResults.length,
      error_count: errors.length,
      errors,
      message: `${uploadResults.length} image(s) uploaded successfully${errors.length > 0 ? ` with ${errors.length} error(s)` : ''}`,
    }, undefined, uploadResults.length > 0 ? 201 : 400);
  } catch (error) {
    console.error('Class images upload error:', error);
    return errorResponse(
      'Failed to upload class images',
      'UPLOAD_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleCertificateUpload(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const supabase = createSupabaseClient();

  try {
    const formData = await req.formData();
    const file = formData.get('file') as File;
    const certificateName = formData.get('name') as string;
    const issuer = formData.get('issuer') as string;
    const dateIssued = formData.get('date') as string;
    const verificationUrl = formData.get('verification_url') as string;

    if (!file || !certificateName || !issuer || !dateIssued) {
      return errorResponse(
        'Missing required fields: file, name, issuer, date',
        'MISSING_FIELDS',
        400
      );
    }

    // Verify user is an instructor
    const { data: instructor, error: instructorError } = await supabase
      .from('instructor_profiles')
      .select('id')
      .eq('user_id', userId)
      .single();

    if (instructorError) {
      return errorResponse('Instructor profile not found', 'NOT_FOUND', 404);
    }

    // Validate certificate file
    const allowedTypes = [...ALLOWED_DOCUMENT_TYPES, ...ALLOWED_IMAGE_TYPES];
    const validation = validateFileUpload(file, MAX_DOCUMENT_SIZE_MB, allowedTypes);
    if (!validation.valid) {
      return errorResponse(validation.error!, 'FILE_VALIDATION_ERROR', 400);
    }

    // Generate secure filename
    const fileExtension = file.name.split('.').pop();
    const certificateFileName = `cert_${instructor.id}_${generateId('cert')}.${fileExtension}`;
    const filePath = `certifications/${userId}/${certificateFileName}`;

    // Upload to private bucket (certificates should be private)
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from('instructor-documents')
      .upload(filePath, file, {
        cacheControl: '31536000', // 1 year
        upsert: false,
        contentType: file.type,
      });

    if (uploadError) {
      return errorResponse(
        'Failed to upload certificate',
        'UPLOAD_ERROR',
        500,
        { supabase_error: uploadError }
      );
    }

    // Get current instructor certifications
    const { data: currentInstructor } = await supabase
      .from('instructor_profiles')
      .select('certifications')
      .eq('id', instructor.id)
      .single();

    const existingCertifications = currentInstructor?.certifications || [];
    const newCertification = {
      name: sanitizeInput(certificateName),
      issuer: sanitizeInput(issuer),
      date: dateIssued,
      verification_url: verificationUrl || null,
      document_url: filePath,
      verified: false, // Will be verified by admin
      uploaded_at: new Date().toISOString(),
    };

    // Update instructor profile with new certification
    const { error: updateError } = await supabase
      .from('instructor_profiles')
      .update({
        certifications: [...existingCertifications, newCertification],
        updated_at: new Date().toISOString(),
      })
      .eq('id', instructor.id);

    if (updateError) {
      // Cleanup uploaded file if database update fails
      await supabase.storage.from('instructor-documents').remove([filePath]);
      return errorResponse(
        'Failed to save certification',
        'SAVE_ERROR',
        500,
        { supabase_error: updateError }
      );
    }

    return createResponse({
      certification: newCertification,
      file_path: filePath,
      file_size: file.size,
      file_size_formatted: formatFileSize(file.size),
      verification_status: 'pending',
      message: 'Certificate uploaded successfully. It will be reviewed for verification.',
    }, undefined, 201);
  } catch (error) {
    console.error('Certificate upload error:', error);
    return errorResponse(
      'Failed to upload certificate',
      'UPLOAD_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleGenerateSignedUrl(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const body = await req.json();
  const validation = validateBody(body, ['file_path', 'bucket']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { file_path, bucket, expires_in = 3600 } = validation.data;
  const supabase = createSupabaseClient();

  try {
    // Verify file ownership for private files
    if (bucket.includes('private') || bucket.includes('instructor-documents')) {
      const { data: file, error: fileError } = await supabase
        .from('user_files')
        .select('user_id')
        .eq('file_path', file_path)
        .eq('bucket', bucket)
        .single();

      if (fileError || file.user_id !== userId) {
        return errorResponse('File not found or access denied', 'FORBIDDEN', 403);
      }
    }

    // Generate signed URL
    const { data: signedUrlData, error: urlError } = await supabase.storage
      .from(bucket)
      .createSignedUrl(file_path, expires_in);

    if (urlError) {
      return errorResponse(
        'Failed to generate signed URL',
        'URL_ERROR',
        500,
        { supabase_error: urlError }
      );
    }

    return createResponse({
      signed_url: signedUrlData.signedUrl,
      expires_in,
      expires_at: new Date(Date.now() + expires_in * 1000).toISOString(),
      file_path,
      bucket,
    });
  } catch (error) {
    console.error('Generate signed URL error:', error);
    return errorResponse(
      'Failed to generate signed URL',
      'URL_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleGetUserFiles(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const url = new URL(req.url);
  const fileType = url.searchParams.get('type'); // Filter by file type
  const limit = parseInt(url.searchParams.get('limit') || '50');
  const offset = parseInt(url.searchParams.get('offset') || '0');
  const supabase = createSupabaseClient(authHeader);

  try {
    let query = supabase
      .from('user_files')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (fileType) {
      query = query.eq('file_type', fileType);
    }

    const { data: files, error } = await query;

    if (error) {
      return errorResponse(
        'Failed to get user files',
        'FETCH_ERROR',
        500,
        { supabase_error: error }
      );
    }

    // Enhance files with formatted data
    const enhancedFiles = files?.map(file => ({
      ...file,
      file_size_formatted: formatFileSize(file.file_size),
      download_url: file.is_public 
        ? file.public_url 
        : `/storage/download?file_id=${file.id}`,
    }));

    return createResponse({
      files: enhancedFiles,
      count: files?.length || 0,
      filter: { type: fileType },
    });
  } catch (error) {
    console.error('Get user files error:', error);
    return errorResponse(
      'Failed to get user files',
      'FETCH_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleDeleteFile(req: Request, authHeader?: string, fileId: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const supabase = createSupabaseClient();

  try {
    // Get file info and verify ownership
    const { data: file, error: fileError } = await supabase
      .from('user_files')
      .select('*')
      .eq('id', fileId)
      .eq('user_id', userId)
      .single();

    if (fileError) {
      return errorResponse('File not found', 'NOT_FOUND', 404);
    }

    // Delete from storage
    const { error: storageError } = await supabase.storage
      .from(file.bucket)
      .remove([file.file_path]);

    if (storageError) {
      console.error('Storage deletion error:', storageError);
    }

    // Delete from database
    const { error: dbError } = await supabase
      .from('user_files')
      .delete()
      .eq('id', fileId);

    if (dbError) {
      return errorResponse(
        'Failed to delete file record',
        'DELETE_ERROR',
        500,
        { supabase_error: dbError }
      );
    }

    return createResponse({
      file_id: fileId,
      file_name: file.file_name,
      message: 'File deleted successfully',
    });
  } catch (error) {
    console.error('Delete file error:', error);
    return errorResponse(
      'Failed to delete file',
      'DELETE_ERROR',
      500,
      { error: error.message }
    );
  }
}

// Helper functions
function formatFileSize(bytes: number): string {
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  if (bytes === 0) return '0 Bytes';
  const i = Math.floor(Math.log(bytes) / Math.log(1024));
  return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
}

async function queueImageProcessing(
  id: string,
  filePath: string,
  bucket: string,
  options: {
    generateThumbnails?: boolean;
    sizes?: number[];
    optimize?: boolean;
    watermark?: boolean;
  } = {}
): Promise<void> {
  // In a real implementation, this would queue a job for image processing
  // For now, we'll just log the processing request
  console.log('Queuing image processing:', {
    id,
    filePath,
    bucket,
    options,
    timestamp: new Date().toISOString(),
  });

  // TODO: Implement actual image processing with a service like:
  // - Supabase Edge Functions for resize/optimize
  // - External service like Cloudinary or ImageKit
  // - Background job processing with queues
}