# StudioProfileStep.tsx Photo Upload UI Update

## Location
File: `/Users/chromefang.exe/Projects/HobbiApp/web-partner/app/onboarding/steps/StudioProfileStep.tsx`  
Lines: 326-338

## Replace This Code:

```typescript
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {[...Array(6)].map((_, index) => (
              <div
                key={index}
                className="aspect-square bg-gray-100 rounded-lg flex items-center justify-center border-2 border-dashed border-gray-300 hover:border-gray-400 transition-colors cursor-pointer"
              >
                <div className="text-center">
                  <Camera className="h-8 w-8 text-gray-400 mx-auto mb-2" />
                  <p className="text-sm text-gray-500">Add Photo</p>
                </div>
              </div>
            ))}
          </div>
```

## With This Code:

```typescript
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {/* Existing photos */}
            {formData.photos.map((url: string, index: number) => (
              <div key={index} className="relative aspect-square">
                <img
                  src={url}
                  alt={`Studio photo ${index + 1}`}
                  className="w-full h-full object-cover rounded-lg"
                />
                <button
                  type="button"
                  onClick={() => handleRemovePhoto(index)}
                  className="absolute top-2 right-2 p-1 bg-red-500 text-white rounded-full hover:bg-red-600 transition-colors"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
            ))}

            {/* Upload button */}
            {formData.photos.length < 10 && (
              <label className="aspect-square bg-gray-100 rounded-lg flex items-center justify-center border-2 border-dashed border-gray-300 hover:border-gray-400 transition-colors cursor-pointer">
                <input
                  type="file"
                  multiple
                  accept="image/*"
                  onChange={(e) => handlePhotoUpload(e.target.files)}
                  className="hidden"
                  disabled={uploadingPhotos}
                />
                <div className="text-center">
                  {uploadingPhotos ? (
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-gray-400 mx-auto" />
                  ) : (
                    <>
                      <Camera className="h-8 w-8 text-gray-400 mx-auto mb-2" />
                      <p className="text-sm text-gray-500">Add Photo</p>
                    </>
                  )}
                </div>
              </label>
            )}
          </div>
```

## What This Does:

1. **Displays uploaded photos** - Shows all photos in `formData.photos` array
2. **Delete button** - Red X button on each photo to remove it
3. **Upload button** - Shows "Add Photo" placeholder when < 10 photos
4. **Loading state** - Shows spinner while `uploadingPhotos` is true
5. **File input** - Hidden input that triggers `handlePhotoUpload` on change

## Manual Update Steps:

1. Open `StudioProfileStep.tsx`
2. Find line 326 (search for `<div className="grid grid-cols-2 md:grid-cols-4 gap-4">`)
3. Select lines 326-338 (the entire grid div)
4. Replace with the new code above
5. Save the file
