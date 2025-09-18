'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Package,
  Plus,
  Search,
  Filter,
  AlertTriangle,
  TrendingDown,
  TrendingUp,
  DollarSign,
  Calendar,
  ShoppingCart,
  BarChart3,
  Edit,
  Trash2,
  Download,
  Upload,
  RefreshCw,
  CheckCircle,
  Clock,
  Palette,
  Hammer,
  Brush,
  Scissors
} from 'lucide-react';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { formatCurrency } from '@/lib/utils';

interface Material {
  id: string;
  name: string;
  category: 'clay' | 'glazes' | 'tools' | 'paints' | 'brushes' | 'canvas' | 'wood' | 'hardware' | 'other';
  subcategory?: string;
  current_stock: number;
  unit_type: 'pieces' | 'pounds' | 'liters' | 'feet' | 'sheets' | 'grams';
  unit_cost: number;
  reorder_level: number;
  supplier_name?: string;
  supplier_contact?: string;
  supplier_sku?: string;
  last_ordered_at?: string;
  usage_rate_per_month: number; // Average usage
  shelf_life_days?: number; // For perishable materials
  storage_location?: string;
  notes?: string;
  auto_reorder: boolean;
}

interface MaterialUsage {
  id: string;
  material_id: string;
  workshop_id: string;
  workshop_name: string;
  workshop_category: string;
  quantity_used: number;
  workshop_date: string;
  cost_per_workshop: number;
  participants: number;
  cost_per_participant: number;
}

interface Supplier {
  id: string;
  name: string;
  contact_email?: string;
  contact_phone?: string;
  website?: string;
  payment_terms: string;
  delivery_time_days: number;
  minimum_order: number;
  specialties: string[];
  rating: number;
  notes?: string;
}

interface MaterialOrder {
  id: string;
  supplier_id: string;
  supplier_name: string;
  status: 'pending' | 'ordered' | 'shipped' | 'delivered' | 'cancelled';
  order_date: string;
  expected_delivery?: string;
  total_cost: number;
  items: Array<{
    material_id: string;
    material_name: string;
    quantity: number;
    unit_cost: number;
    total_cost: number;
  }>;
  tracking_number?: string;
  notes?: string;
}

interface MaterialInventoryManagerProps {
  studioId: string;
}

const CATEGORY_ICONS = {
  clay: Package,
  glazes: Palette,
  tools: Hammer,
  paints: Palette,
  brushes: Brush,
  canvas: Scissors,
  wood: Package,
  hardware: Hammer,
  other: Package,
};

const CATEGORY_COLORS = {
  clay: 'bg-amber-100 text-amber-800',
  glazes: 'bg-blue-100 text-blue-800',
  tools: 'bg-gray-100 text-gray-800',
  paints: 'bg-purple-100 text-purple-800',
  brushes: 'bg-green-100 text-green-800',
  canvas: 'bg-orange-100 text-orange-800',
  wood: 'bg-yellow-100 text-yellow-800',
  hardware: 'bg-indigo-100 text-indigo-800',
  other: 'bg-gray-100 text-gray-800',
};

export function MaterialInventoryManager({ studioId }: MaterialInventoryManagerProps) {
  const [materials, setMaterials] = useState<Material[]>([]);
  const [materialUsage, setMaterialUsage] = useState<MaterialUsage[]>([]);
  const [suppliers, setSuppliers] = useState<Supplier[]>([]);
  const [orders, setOrders] = useState<MaterialOrder[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [showLowStock, setShowLowStock] = useState(false);
  const [showAddModal, setShowAddModal] = useState(false);
  const [selectedMaterial, setSelectedMaterial] = useState<Material | null>(null);
  const [viewMode, setViewMode] = useState<'inventory' | 'usage' | 'suppliers' | 'orders'>('inventory');

  useEffect(() => {
    fetchInventoryData();
  }, [studioId]);

  const fetchInventoryData = async () => {
    setLoading(true);
    try {
      // Mock data - replace with actual API calls
      const mockMaterials: Material[] = [
        {
          id: '1',
          name: 'Porcelain Clay',
          category: 'clay',
          subcategory: 'throwing_clay',
          current_stock: 45,
          unit_type: 'pounds',
          unit_cost: 2.50,
          reorder_level: 20,
          supplier_name: 'Creative Clay Supply',
          usage_rate_per_month: 60,
          shelf_life_days: 365,
          storage_location: 'Clay Storage Room',
          auto_reorder: true,
        },
        {
          id: '2',
          name: 'Acrylic Paint - Primary Set',
          category: 'paints',
          subcategory: 'acrylic',
          current_stock: 8,
          unit_type: 'pieces',
          unit_cost: 15.99,
          reorder_level: 12,
          supplier_name: 'Art Supplies Plus',
          usage_rate_per_month: 15,
          storage_location: 'Paint Cabinet A',
          auto_reorder: false,
        },
        {
          id: '3',
          name: 'Clear Glaze',
          category: 'glazes',
          current_stock: 3,
          unit_type: 'liters',
          unit_cost: 25.00,
          reorder_level: 5,
          supplier_name: 'Ceramic Supply Co',
          usage_rate_per_month: 8,
          shelf_life_days: 180,
          storage_location: 'Glaze Room',
          auto_reorder: true,
        },
        {
          id: '4',
          name: 'Pottery Tools Set',
          category: 'tools',
          current_stock: 12,
          unit_type: 'pieces',
          unit_cost: 35.00,
          reorder_level: 8,
          supplier_name: 'Professional Pottery',
          usage_rate_per_month: 2,
          storage_location: 'Tool Cabinet',
          auto_reorder: false,
        },
      ];

      const mockUsage: MaterialUsage[] = [
        {
          id: '1',
          material_id: '1',
          workshop_id: 'w1',
          workshop_name: 'Beginner Pottery Wheel',
          workshop_category: 'pottery',
          quantity_used: 12,
          workshop_date: '2025-09-15',
          cost_per_workshop: 30.00,
          participants: 8,
          cost_per_participant: 3.75,
        },
        {
          id: '2',
          material_id: '2',
          workshop_id: 'w2',
          workshop_name: 'Watercolor Landscapes',
          workshop_category: 'painting',
          quantity_used: 2,
          workshop_date: '2025-09-16',
          cost_per_workshop: 31.98,
          participants: 10,
          cost_per_participant: 3.20,
        },
      ];

      const mockSuppliers: Supplier[] = [
        {
          id: '1',
          name: 'Creative Clay Supply',
          contact_email: 'orders@creativeclay.com',
          contact_phone: '(604) 555-0123',
          website: 'creativeclay.com',
          payment_terms: 'Net 30',
          delivery_time_days: 5,
          minimum_order: 100,
          specialties: ['clay', 'glazes', 'pottery_tools'],
          rating: 4.8,
        },
        {
          id: '2',
          name: 'Art Supplies Plus',
          contact_email: 'sales@artsuppliesplus.ca',
          contact_phone: '(604) 555-0456',
          payment_terms: 'Net 15',
          delivery_time_days: 3,
          minimum_order: 50,
          specialties: ['paints', 'brushes', 'canvas'],
          rating: 4.5,
        },
      ];

      const mockOrders: MaterialOrder[] = [
        {
          id: '1',
          supplier_id: '1',
          supplier_name: 'Creative Clay Supply',
          status: 'shipped',
          order_date: '2025-09-12',
          expected_delivery: '2025-09-18',
          total_cost: 245.50,
          items: [
            {
              material_id: '1',
              material_name: 'Porcelain Clay',
              quantity: 50,
              unit_cost: 2.50,
              total_cost: 125.00,
            },
            {
              material_id: '3',
              material_name: 'Clear Glaze',
              quantity: 4,
              unit_cost: 25.00,
              total_cost: 100.00,
            },
          ],
          tracking_number: 'TR123456789',
        },
      ];

      setMaterials(mockMaterials);
      setMaterialUsage(mockUsage);
      setSuppliers(mockSuppliers);
      setOrders(mockOrders);
    } catch (error) {
      console.error('Failed to fetch inventory data:', error);
    } finally {
      setLoading(false);
    }
  };

  const getLowStockMaterials = () => {
    return materials.filter(material => material.current_stock <= material.reorder_level);
  };

  const getInventoryValue = () => {
    return materials.reduce((total, material) => total + (material.current_stock * material.unit_cost), 0);
  };

  const getMonthlyCosts = () => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    return materialUsage
      .filter(usage => new Date(usage.workshop_date) >= thirtyDaysAgo)
      .reduce((total, usage) => total + usage.cost_per_workshop, 0);
  };

  const getFilteredMaterials = () => {
    let filtered = materials;

    if (selectedCategory !== 'all') {
      filtered = filtered.filter(material => material.category === selectedCategory);
    }

    if (showLowStock) {
      filtered = filtered.filter(material => material.current_stock <= material.reorder_level);
    }

    if (searchQuery) {
      filtered = filtered.filter(material =>
        material.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        material.supplier_name?.toLowerCase().includes(searchQuery.toLowerCase())
      );
    }

    return filtered;
  };

  const getStockStatus = (material: Material) => {
    const stockPercentage = (material.current_stock / material.reorder_level) * 100;

    if (stockPercentage <= 50) return { status: 'critical', color: 'text-red-600' };
    if (stockPercentage <= 100) return { status: 'low', color: 'text-yellow-600' };
    if (stockPercentage <= 150) return { status: 'adequate', color: 'text-green-600' };
    return { status: 'high', color: 'text-blue-600' };
  };

  const handleCreateOrder = (material: Material) => {
    // Logic to create purchase order
    console.log('Creating order for:', material.name);
  };

  const renderInventoryView = () => (
    <div className="space-y-6">
      {/* Inventory Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Total Items</p>
                <p className="text-2xl font-bold">{materials.length}</p>
              </div>
              <Package className="h-8 w-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Inventory Value</p>
                <p className="text-2xl font-bold">{formatCurrency(getInventoryValue())}</p>
              </div>
              <DollarSign className="h-8 w-8 text-green-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Low Stock Items</p>
                <p className="text-2xl font-bold text-red-600">{getLowStockMaterials().length}</p>
              </div>
              <AlertTriangle className="h-8 w-8 text-red-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Monthly Costs</p>
                <p className="text-2xl font-bold">{formatCurrency(getMonthlyCosts())}</p>
              </div>
              <TrendingUp className="h-8 w-8 text-purple-500" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Low Stock Alert */}
      {getLowStockMaterials().length > 0 && (
        <Card className="border-red-200 bg-red-50">
          <CardHeader>
            <CardTitle className="flex items-center text-red-800">
              <AlertTriangle className="h-5 w-5 mr-2" />
              Low Stock Alert
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {getLowStockMaterials().slice(0, 3).map(material => (
                <div key={material.id} className="flex items-center justify-between p-2 bg-white rounded border">
                  <div>
                    <p className="font-medium text-red-800">{material.name}</p>
                    <p className="text-sm text-red-600">
                      Only {material.current_stock} {material.unit_type} remaining
                    </p>
                  </div>
                  <Button size="sm" variant="outline" onClick={() => handleCreateOrder(material)}>
                    <ShoppingCart className="h-4 w-4 mr-2" />
                    Order
                  </Button>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Filters and Search */}
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="flex-1">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
            <input
              type="text"
              placeholder="Search materials or suppliers..."
              className="pl-10 pr-4 py-2 w-full border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
        </div>
        <div className="flex gap-2">
          <select
            className="px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500"
            value={selectedCategory}
            onChange={(e) => setSelectedCategory(e.target.value)}
          >
            <option value="all">All Categories</option>
            <option value="clay">Clay</option>
            <option value="glazes">Glazes</option>
            <option value="tools">Tools</option>
            <option value="paints">Paints</option>
            <option value="brushes">Brushes</option>
            <option value="canvas">Canvas</option>
            <option value="wood">Wood</option>
            <option value="hardware">Hardware</option>
          </select>
          <Button
            variant={showLowStock ? 'default' : 'outline'}
            onClick={() => setShowLowStock(!showLowStock)}
          >
            <AlertTriangle className="h-4 w-4 mr-2" />
            Low Stock
          </Button>
        </div>
      </div>

      {/* Materials Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {getFilteredMaterials().map((material, index) => {
          const Icon = CATEGORY_ICONS[material.category];
          const stockStatus = getStockStatus(material);

          return (
            <motion.div
              key={material.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
            >
              <Card className="hover:shadow-md transition-shadow cursor-pointer" onClick={() => setSelectedMaterial(material)}>
                <CardContent className="p-4">
                  <div className="flex items-start justify-between">
                    <div className="flex items-center space-x-3">
                      <div className={`p-2 rounded-lg ${CATEGORY_COLORS[material.category]}`}>
                        <Icon className="h-4 w-4" />
                      </div>
                      <div className="flex-1">
                        <h3 className="font-medium text-gray-900">{material.name}</h3>
                        <p className="text-sm text-gray-600">{material.supplier_name}</p>
                      </div>
                    </div>
                    <Badge variant={material.category as any} className="text-xs">
                      {material.category}
                    </Badge>
                  </div>

                  <div className="mt-4 space-y-2">
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-gray-600">Current Stock:</span>
                      <span className={`font-medium ${stockStatus.color}`}>
                        {material.current_stock} {material.unit_type}
                      </span>
                    </div>

                    <div className="flex justify-between items-center">
                      <span className="text-sm text-gray-600">Reorder Level:</span>
                      <span className="text-sm font-medium">{material.reorder_level} {material.unit_type}</span>
                    </div>

                    <div className="flex justify-between items-center">
                      <span className="text-sm text-gray-600">Unit Cost:</span>
                      <span className="text-sm font-medium">{formatCurrency(material.unit_cost)}</span>
                    </div>

                    <div className="flex justify-between items-center">
                      <span className="text-sm text-gray-600">Total Value:</span>
                      <span className="text-sm font-bold">
                        {formatCurrency(material.current_stock * material.unit_cost)}
                      </span>
                    </div>

                    {/* Stock Level Indicator */}
                    <div className="w-full bg-gray-200 rounded-full h-2 mt-2">
                      <div
                        className={`h-2 rounded-full transition-all duration-300 ${
                          stockStatus.status === 'critical' ? 'bg-red-500' :
                          stockStatus.status === 'low' ? 'bg-yellow-500' :
                          stockStatus.status === 'adequate' ? 'bg-green-500' : 'bg-blue-500'
                        }`}
                        style={{
                          width: `${Math.min((material.current_stock / (material.reorder_level * 2)) * 100, 100)}%`
                        }}
                      ></div>
                    </div>

                    {/* Auto-reorder indicator */}
                    <div className="flex items-center justify-between text-xs">
                      <span className={stockStatus.color}>{stockStatus.status.toUpperCase()}</span>
                      {material.auto_reorder && (
                        <Badge variant="secondary" className="text-xs">
                          Auto-reorder
                        </Badge>
                      )}
                    </div>
                  </div>

                  {material.current_stock <= material.reorder_level && (
                    <div className="mt-3 pt-3 border-t">
                      <Button
                        size="sm"
                        className="w-full"
                        variant="outline"
                        onClick={(e) => {
                          e.stopPropagation();
                          handleCreateOrder(material);
                        }}
                      >
                        <ShoppingCart className="h-4 w-4 mr-2" />
                        Reorder Now
                      </Button>
                    </div>
                  )}
                </CardContent>
              </Card>
            </motion.div>
          );
        })}
      </div>
    </div>
  );

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {[...Array(6)].map((_, i) => (
            <Card key={i} className="animate-pulse">
              <CardContent className="p-6">
                <div className="h-24 bg-gray-200 rounded"></div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="space-y-6"
    >
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Material Inventory</h1>
          <p className="text-gray-600">Manage your workshop materials and supplies</p>
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant={viewMode === 'inventory' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setViewMode('inventory')}
          >
            <Package className="h-4 w-4 mr-2" />
            Inventory
          </Button>
          <Button
            variant={viewMode === 'usage' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setViewMode('usage')}
          >
            <BarChart3 className="h-4 w-4 mr-2" />
            Usage
          </Button>
          <Button
            variant={viewMode === 'orders' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setViewMode('orders')}
          >
            <ShoppingCart className="h-4 w-4 mr-2" />
            Orders
          </Button>
          <Button variant="creative">
            <Plus className="h-4 w-4 mr-2" />
            Add Material
          </Button>
        </div>
      </div>

      {/* Main Content */}
      {viewMode === 'inventory' && renderInventoryView()}
    </motion.div>
  );
}