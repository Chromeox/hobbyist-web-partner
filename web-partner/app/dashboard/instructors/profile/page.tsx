'use client';

import React, { useState, useEffect } from 'react';
import { createClientComponentClient } from '@supabase/auth-helpers-nextjs';
import { useRouter } from 'next/navigation';
import {
  User,
  Mail,
  Phone,
  Info,
  Save,
  Loader2,
  AlertCircle,
  CheckCircle,
  Briefcase,
  Award,
  Image as ImageIcon,
  PlusCircle,
  X,
  Upload
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { useAuthContext } from '@/lib/context/AuthContext';

interface InstructorProfileData {
  id: string;
  first_name: string;
  last_name: string;
  email: string;
  bio?: string;
  phone_number?: string;
  profile_picture_url?: string;
  qualifications?: string[];
  specialties?: string[];
  portfolio_images?: string[];
}

export default function InstructorProfileManagementPage() {
  const { user } = useAuthContext();
  const supabase = createClientComponentClient();
  const router = useRouter();

  const [profile, setProfile] = useState<InstructorProfileData | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [bio, setBio] = useState('');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [profilePictureFile, setProfilePictureFile] = useState<File | null>(null);
  const [qualifications, setQualifications] = useState<string[]>([]);
  const [newQualification, setNewQualification] = useState('');
  const [specialties, setSpecialties] = useState<string[]>([]);
  const [newSpecialty, setNewSpecialty] = useState('');
  const [portfolioImages, setPortfolioImages] = useState<string[]>([]); // URLs
  const [newPortfolioImageFile, setNewPortfolioImageFile] = useState<File | null>(null);

  useEffect(() => {
    if (user) {
      fetchProfile();
    } else {
      router.push('/auth/signin'); // Redirect if not logged in
    }
  }, [user]);

  const fetchProfile = async () => {
    setLoading(true);
    setError(null);
    try {
      const { data, error: supabaseError } = await supabase
        .from('instructors') // Assuming an 'instructors' table
        .select('id, first_name, last_name, email, bio, phone_number, profile_picture_url, qualifications, specialties, portfolio_images')
        .eq('id', user?.id) // Filter by user ID
        .single();

      if (supabaseError) throw supabaseError;

      if (data) {
        setProfile(data);
        setFirstName(data.first_name || '');
        setLastName(data.last_name || '');
        setBio(data.bio || '');
        setPhoneNumber(data.phone_number || '');
        setQualifications(data.qualifications || []);
        setSpecialties(data.specialties || []);
        setPortfolioImages(data.portfolio_images || []);
      }
    } catch (err: any) {
      console.error('Error fetching instructor profile:', err.message);
      setError('Failed to load profile. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleSaveProfile = async () => {
    if (!user) return;
    setSaving(true);
    setError(null);
    setSuccess(null);

    let profilePictureUrl = profile?.profile_picture_url;

    try {
      // Upload new profile picture if selected
      if (profilePictureFile) {
        const { data, error: uploadError } = await supabase.storage
          .from('profile-pictures') // Assuming a storage bucket named 'profile-pictures'
          .upload(`${user.id}/${profilePictureFile.name}`, profilePictureFile, { cacheControl: '3600', upsert: true });

        if (uploadError) throw uploadError;
        profilePictureUrl = `${supabase.storage.from('profile-pictures').getPublicUrl(data.path).data.publicUrl}`;
      }

      // Update instructor profile in database
      const { error: updateError } = await supabase
        .from('instructors')
        .update({
          first_name: firstName,
          last_name: lastName,
          bio: bio,
          phone_number: phoneNumber,
          profile_picture_url: profilePictureUrl,
          qualifications: qualifications,
          specialties: specialties,
          portfolio_images: portfolioImages,
        })
        .eq('id', user.id);

      if (updateError) throw updateError;

      setSuccess('Profile saved successfully!');
      // Re-fetch profile to ensure UI is updated with latest data
      fetchProfile(); 
    } catch (err: any) {
      console.error('Error saving profile:', err.message);
      setError('Failed to save profile. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  const addQualification = () => {
    if (newQualification.trim() && !qualifications.includes(newQualification.trim())) {
      setQualifications([...qualifications, newQualification.trim()]);
      setNewQualification('');
    }
  };

  const removeQualification = (q: string) => {
    setQualifications(qualifications.filter(qual => qual !== q));
  };

  const addSpecialty = () => {
    if (newSpecialty.trim() && !specialties.includes(newSpecialty.trim())) {
      setSpecialties([...specialties, newSpecialty.trim()]);
      setNewSpecialty('');
    }
  };

  const removeSpecialty = (s: string) => {
    setSpecialties(specialties.filter(spec => spec !== s));
  };

  const handlePortfolioImageChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (event.target.files && event.target.files[0]) {
      setNewPortfolioImageFile(event.target.files[0]);
    }
  };

  const uploadPortfolioImage = async () => {
    if (!newPortfolioImageFile || !user) return;

    setSaving(true);
    setError(null);
    try {
      const { data, error: uploadError } = await supabase.storage
        .from('portfolio-images') // Assuming a storage bucket named 'portfolio-images'
        .upload(`${user.id}/${newPortfolioImageFile.name}`, newPortfolioImageFile, { cacheControl: '3600', upsert: true });

      if (uploadError) throw uploadError;

      const imageUrl = `${supabase.storage.from('portfolio-images').getPublicUrl(data.path).data.publicUrl}`;
      setPortfolioImages(prev => [...prev, imageUrl]);
      setNewPortfolioImageFile(null);
      setSuccess('Portfolio image uploaded!');
    } catch (err: any) {
      console.error('Error uploading portfolio image:', err.message);
      setError('Failed to upload portfolio image.');
    } finally {
      setSaving(false);
    }
  };

  const removePortfolioImage = (url: string) => {
    setPortfolioImages(portfolioImages.filter(img => img !== url));
    // Optionally, delete from storage as well
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <Loader2 className="h-8 w-8 animate-spin text-blue-500" />
        <p className="ml-2 text-gray-600">Loading profile...</p>
      </div>
    );
  }

  return (
    <div className="space-y-6 p-6">
      <h1 className="text-3xl font-bold text-gray-900">Manage Instructor Profile</h1>
      <p className="text-gray-600">Update your public profile, qualifications, and portfolio.</p>

      {error && (
        <div className="p-3 bg-red-100 border border-red-400 text-red-700 rounded-lg flex items-center gap-2">
          <AlertCircle className="h-5 w-5" />
          <p className="text-sm">{error}</p>
        </div>
      )}
      {success && (
        <div className="p-3 bg-green-100 border border-green-400 text-green-700 rounded-lg flex items-center gap-2">
          <CheckCircle className="h-5 w-5" />
          <p className="text-sm">{success}</p>
        </div>
      )}

      <Card>
        <CardHeader>
          <CardTitle>Personal Information</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center space-x-4">
            <Avatar className="h-20 w-20">
              <AvatarImage src={profile?.profile_picture_url || undefined} />
              <AvatarFallback>{firstName.charAt(0)}{lastName.charAt(0)}</AvatarFallback>
            </Avatar>
            <div>
              <Label htmlFor="profilePicture">Profile Picture</Label>
              <Input id="profilePicture" type="file" accept="image/*" onChange={(e) => setProfilePictureFile(e.target.files ? e.target.files[0] : null)} />
            </div>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label htmlFor="firstName">First Name</Label>
              <Input id="firstName" value={firstName} onChange={(e) => setFirstName(e.target.value)} />
            </div>
            <div>
              <Label htmlFor="lastName">Last Name</Label>
              <Input id="lastName" value={lastName} onChange={(e) => setLastName(e.target.value)} />
            </div>
          </div>
          <div>
            <Label htmlFor="bio">Bio</Label>
            <Textarea id="bio" value={bio} onChange={(e) => setBio(e.target.value)} rows={4} />
          </div>
          <div>
            <Label htmlFor="phoneNumber">Phone Number</Label>
            <Input id="phoneNumber" value={phoneNumber} onChange={(e) => setPhoneNumber(e.target.value)} />
          </div>
          <Button onClick={handleSaveProfile} disabled={saving}>
            {saving ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Save className="mr-2 h-4 w-4" />}
            Save Personal Info
          </Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Qualifications & Specialties</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <Label htmlFor="newQualification">Add Qualification</Label>
            <div className="flex gap-2">
              <Input id="newQualification" value={newQualification} onChange={(e) => setNewQualification(e.target.value)} placeholder="e.g., Certified Yoga Instructor" />
              <Button onClick={addQualification} variant="outline">
                <PlusCircle className="h-4 w-4" />
              </Button>
            </div>
            <div className="mt-2 flex flex-wrap gap-2">
              {qualifications.map((q, index) => (
                <Badge key={index} variant="secondary" className="flex items-center gap-1">
                  {q}
                  <X className="h-3 w-3 cursor-pointer" onClick={() => removeQualification(q)} />
                </Badge>
              ))}
            </div>
          </div>

          <div>
            <Label htmlFor="newSpecialty">Add Specialty</Label>
            <div className="flex gap-2">
              <Input id="newSpecialty" value={newSpecialty} onChange={(e) => setNewSpecialty(e.target.value)} placeholder="e.g., Vinyasa Flow" />
              <Button onClick={addSpecialty} variant="outline">
                <PlusCircle className="h-4 w-4" />
              </Button>
            </div>
            <div className="mt-2 flex flex-wrap gap-2">
              {specialties.map((s, index) => (
                <Badge key={index} variant="secondary" className="flex items-center gap-1">
                  {s}
                  <X className="h-3 w-3 cursor-pointer" onClick={() => removeSpecialty(s)} />
                </Badge>
              ))}
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Portfolio Images</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <Label htmlFor="portfolioImage">Upload Image</Label>
            <div className="flex gap-2">
              <Input id="portfolioImage" type="file" accept="image/*" onChange={handlePortfolioImageChange} />
              <Button onClick={uploadPortfolioImage} disabled={!newPortfolioImageFile || saving} variant="outline">
                {saving ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Upload className="mr-2 h-4 w-4" />}
                Upload
              </Button>
            </div>
            <div className="mt-4 grid grid-cols-3 gap-4">
              {portfolioImages.map((url, index) => (
                <div key={index} className="relative group">
                  <img src={url} alt={`Portfolio ${index}`} className="w-full h-32 object-cover rounded-lg" />
                  <Button
                    variant="destructive"
                    size="icon"
                    className="absolute top-1 right-1 opacity-0 group-hover:opacity-100 transition-opacity"
                    onClick={() => removePortfolioImage(url)}
                  >
                    <X className="h-4 w-4" />
                  </Button>
                </div>
              ))}
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
