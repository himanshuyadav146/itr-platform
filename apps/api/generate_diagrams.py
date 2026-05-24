#!/usr/bin/env python3
"""
ITR API Diagram Generator
Generates ER Diagram, DFD, and Architecture Diagram in PDF format
"""

import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.backends.backend_pdf import PdfPages
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch, Rectangle
import datetime

# Define database schema
TABLES = {
    'users': {
        'pk': ['UserId'],
        'fields': ['UserId', 'FirstName', 'MiddleName', 'LastName', 'Email', 'Mobile', 'Password', 'Platform', 'Version', 'CreatedAt', 'UpdatedAt'],
        'type': 'core'
    },
    'services': {
        'pk': ['id'],
        'fields': ['id', 'Name', 'CreatedAt'],
        'type': 'catalog'
    },
    'personal_details': {
        'pk': ['id'],
        'fk': [('UserId', 'users', 'UserId')],
        'fields': ['id', 'UserId', 'PANNumber', 'FirstName', 'MiddleName', 'LastName', 'EMAIL', 'MobileNumber', 'aadharCardNumber', 'Gender', 'DATEOFBIRTH', 'FinancialYear', 'Address', 'Country', 'isActive', 'createdAt', 'createdBy', 'updatedAt', 'updatedBy'],
        'type': 'user_data'
    },
    'document_details': {
        'pk': ['id'],
        'fk': [('UserId', 'users', 'UserId')],
        'fields': ['id', 'UserId', 'PanNumber', 'name', 'type', 'password', 'fileName', 'isActive', 'createdAt', 'createdBy'],
        'type': 'user_data'
    },
    'itr_detail': {
        'pk': ['id'],
        'fk': [('userId', 'users', 'UserId')],
        'fields': ['id', 'userId', 'panNumber', 'financialYear', 'status', 'createdAt', 'updatedAt'],
        'type': 'itr'
    },
    'itr_source': {
        'pk': ['id'],
        'fk': [('itrId', 'itr_detail', 'id')],
        'fields': ['id', 'itrId', 'sourceType', 'sourceName', 'amount', 'createdAt'],
        'type': 'itr'
    },
    'itr_packages': {
        'pk': ['id'],
        'fields': ['id', 'packagename', 'price', 'title1', 'description1', 'title2', 'description2', 'isActive', 'createdAt'],
        'type': 'catalog'
    },
    'payment_info': {
        'pk': ['id'],
        'fk': [('user_id', 'users', 'UserId'), ('package_id', 'itr_packages', 'id')],
        'fields': ['id', 'payment_id', 'user_id', 'package_id', 'pan_number', 'order_id', 'transaction_id', 'subtotal', 'gst_percentage', 'gst_amount', 'grand_total', 'currency', 'payment_status', 'payment_method', 'gateway_name', 'merchant_id', 'gateway_response', 'webhook_data', 'failure_reason', 'callback_url', 'redirect_url', 'is_active', 'created_at', 'updated_at', 'paid_at'],
        'type': 'payment'
    },
    'payment_additional_fees': {
        'pk': ['id'],
        'fields': ['id', 'fee_name', 'fee_amount', 'display_order', 'is_active', 'created_at', 'updated_at'],
        'type': 'payment'
    },
    'itr_order_status': {
        'pk': ['id'],
        'fk': [('user_id', 'users', 'UserId'), ('itr_id', 'itr_detail', 'id')],
        'fields': ['id', 'order_id', 'itr_id', 'user_id', 'payment_id', 'pan_number', 'status_step', 'is_completed', 'completed_at', 'notes', 'has_concern', 'created_at', 'updated_at'],
        'type': 'status'
    },
    'itr_order_concerns': {
        'pk': ['id'],
        'fk': [('status_id', 'itr_order_status', 'id'), ('user_id', 'users', 'UserId')],
        'fields': ['id', 'status_id', 'order_id', 'itr_id', 'user_id', 'concern_type', 'concern_text', 'concern_image_path', 'status', 'resolved_at', 'resolved_by', 'resolution_notes', 'created_at', 'updated_at'],
        'type': 'status'
    },
    'itr_assignments': {
        'pk': ['id'],
        'fk': [('itr_id', 'itr_detail', 'id'), ('user_id', 'users', 'UserId'), ('professional_id', 'users', 'UserId'), ('assigned_by', 'users', 'UserId')],
        'fields': ['id', 'itr_id', 'order_id', 'user_id', 'professional_id', 'assigned_by', 'assignment_date', 'status', 'priority', 'due_date', 'completed_at', 'notes', 'created_at', 'updated_at'],
        'type': 'status'
    }
}

# Color scheme
COLORS = {
    'core': '#E3F2FD',
    'catalog': '#F3E5F5',
    'user_data': '#E8F5E9',
    'itr': '#FFF3E0',
    'payment': '#FCE4EC',
    'status': '#E0F2F1'
}

def generate_er_diagram():
    """Generate Entity Relationship Diagram"""
    fig, ax = plt.subplots(figsize=(20, 16))
    ax.set_xlim(0, 20)
    ax.set_ylim(0, 16)
    ax.axis('off')
    
    # Calculate positions for tables
    positions = {
        'users': (2, 14),
        'services': (10, 14),
        'personal_details': (1, 10),
        'document_details': (4, 10),
        'itr_detail': (7, 10),
        'itr_source': (10, 10),
        'itr_packages': (13, 14),
        'payment_info': (10, 6),
        'payment_additional_fees': (13, 6),
        'itr_order_status': (4, 6),
        'itr_order_concerns': (1, 6),
        'itr_assignments': (7, 2)
    }
    
    # Draw entities (tables)
    table_boxes = {}
    for table_name, (x, y) in positions.items():
        table_info = TABLES[table_name]
        color = COLORS[table_info['type']]
        
        # Draw table box
        pk_fields = [f for f in table_info['fields'] if f in table_info['pk']]
        key_fields = pk_fields + [fk[0] for fk in table_info.get('fk', [])]
        other_fields = [f for f in table_info['fields'] if f not in key_fields][:5]  # Limit to 5 other fields
        
        # Calculate box height
        num_lines = 1 + len(pk_fields) + len(table_info.get('fk', [])) + min(len(other_fields), 5) + (1 if len(other_fields) > 5 else 0)
        height = num_lines * 0.35 + 0.4
        
        box = FancyBboxPatch((x-0.8, y-height/2), 1.6, height,
                            boxstyle="round,pad=0.1", 
                            facecolor=color, 
                            edgecolor='black', 
                            linewidth=1.5)
        ax.add_patch(box)
        
        # Table name (header)
        ax.text(x, y+height/2-0.15, table_name, 
               ha='center', va='top', fontsize=10, fontweight='bold',
               bbox=dict(boxstyle='round,pad=0.1', facecolor='white', edgecolor='black'))
        
        # Primary key
        y_offset = y+height/2-0.4
        for pk in pk_fields:
            ax.text(x-0.7, y_offset, f"PK: {pk}", ha='left', va='top', fontsize=8, style='italic')
            y_offset -= 0.3
        
        # Foreign keys
        for fk_field, ref_table, ref_field in table_info.get('fk', []):
            ax.text(x-0.7, y_offset, f"FK: {fk_field} → {ref_table}.{ref_field}", 
                   ha='left', va='top', fontsize=7, style='italic', color='blue')
            y_offset -= 0.25
        
        # Separator
        if pk_fields or table_info.get('fk'):
            y_offset -= 0.1
            ax.plot([x-0.8, x+0.8], [y_offset, y_offset], 'k-', linewidth=0.5)
            y_offset -= 0.1
        
        # Other fields
        for field in other_fields:
            ax.text(x-0.7, y_offset, field, ha='left', va='top', fontsize=7)
            y_offset -= 0.25
        
        if len(other_fields) > 5:
            ax.text(x-0.7, y_offset, "...", ha='left', va='top', fontsize=7)
        
        table_boxes[table_name] = (x, y, height)
    
    # Draw relationships
    relationships = [
        ('users', 'personal_details', '1', 'N'),
        ('users', 'document_details', '1', 'N'),
        ('users', 'itr_detail', '1', 'N'),
        ('users', 'payment_info', '1', 'N'),
        ('users', 'itr_order_status', '1', 'N'),
        ('users', 'itr_order_concerns', '1', 'N'),
        ('itr_detail', 'itr_source', '1', 'N'),
        ('itr_packages', 'payment_info', '1', 'N'),
        ('itr_detail', 'itr_order_status', '1', 'N'),
        ('itr_order_status', 'itr_order_concerns', '1', 'N'),
        ('itr_detail', 'itr_assignments', '1', 'N'),
        ('users', 'itr_assignments', '1', 'N'),
    ]
    
    for from_table, to_table, card_from, card_to in relationships:
        if from_table in positions and to_table in positions:
            x1, y1, h1 = table_boxes[from_table]
            x2, y2, h2 = table_boxes[to_table]
            
            # Draw arrow
            if abs(x2-x1) > abs(y2-y1):  # Horizontal relationship
                if x2 > x1:
                    start = (x1+0.8, y1)
                    end = (x2-0.8, y2)
                else:
                    start = (x1-0.8, y1)
                    end = (x2+0.8, y2)
            else:  # Vertical relationship
                if y2 > y1:
                    start = (x1, y1+h1/2)
                    end = (x2, y2-h2/2)
                else:
                    start = (x1, y1-h1/2)
                    end = (x2, y2+h2/2)
            
            arrow = FancyArrowPatch(start, end,
                                  arrowstyle='->', 
                                  mutation_scale=20,
                                  linewidth=1.5,
                                  color='darkblue',
                                  connectionstyle='arc3,rad=0.1')
            ax.add_patch(arrow)
            
            # Add cardinality labels
            mid_x, mid_y = (start[0] + end[0])/2, (start[1] + end[1])/2
            ax.text(mid_x, mid_y-0.2, f"{card_from}:{card_to}", 
                   ha='center', va='center', fontsize=8, 
                   bbox=dict(boxstyle='round,pad=0.2', facecolor='white', edgecolor='darkblue'))
    
    ax.set_title('Entity Relationship Diagram (ERD)\nITR API Database Schema', 
                fontsize=16, fontweight='bold', pad=20)
    
    # Add legend
    legend_elements = [mpatches.Patch(facecolor=color, edgecolor='black', label=label) 
                      for label, color in [('Core Tables', COLORS['core']),
                                          ('Catalog Tables', COLORS['catalog']),
                                          ('User Data', COLORS['user_data']),
                                          ('ITR Data', COLORS['itr']),
                                          ('Payment Data', COLORS['payment']),
                                          ('Status Data', COLORS['status'])]]
    ax.legend(handles=legend_elements, loc='upper right', fontsize=9)
    
    plt.tight_layout()
    return fig

def generate_dfd_level0():
    """Generate DFD Level 0 (Context Diagram)"""
    fig, ax = plt.subplots(figsize=(14, 10))
    ax.set_xlim(0, 14)
    ax.set_ylim(0, 10)
    ax.axis('off')
    
    # Center system
    center_x, center_y = 7, 5
    system_box = FancyBboxPatch((center_x-2, center_y-1.5), 4, 3,
                               boxstyle="round,pad=0.2",
                               facecolor='#E3F2FD',
                               edgecolor='darkblue',
                               linewidth=2)
    ax.add_patch(system_box)
    ax.text(center_x, center_y, 'ITR API\nSystem', ha='center', va='center',
           fontsize=14, fontweight='bold')
    
    # External entities
    entities = [
        ('User', 2, 5),
        ('Payment Gateway', 12, 5),
        ('Admin', 7, 8.5)
    ]
    
    for name, x, y in entities:
        entity_box = FancyBboxPatch((x-1, y-0.5), 2, 1,
                                   boxstyle="round,pad=0.1",
                                   facecolor='#FFF9C4',
                                   edgecolor='orange',
                                   linewidth=1.5)
        ax.add_patch(entity_box)
        ax.text(x, y, name, ha='center', va='center', fontsize=11, fontweight='bold')
    
    # Data flows
    flows = [
        ('User', 'ITR API System', 'Login Request, Personal Details, Documents, Payment Request'),
        ('ITR API System', 'User', 'Token, Status Updates, ITR Details'),
        ('ITR API System', 'Payment Gateway', 'Payment Request'),
        ('Payment Gateway', 'ITR API System', 'Payment Status, Webhook'),
        ('Admin', 'ITR API System', 'Status Updates, Resolution'),
        ('ITR API System', 'Admin', 'Concerns, Order Status')
    ]
    
    for from_entity, to_entity, label in flows:
        if from_entity == 'User':
            start = (3, 5)
        elif from_entity == 'Payment Gateway':
            start = (11, 5)
        elif from_entity == 'Admin':
            start = (7, 8)
        else:
            start = (center_x, center_y)
        
        if to_entity == 'User':
            end = (3, 5)
        elif to_entity == 'Payment Gateway':
            end = (11, 5)
        elif to_entity == 'Admin':
            end = (7, 8)
        else:
            end = (center_x, center_y)
        
        if from_entity != 'ITR API System':
            arrow = FancyArrowPatch(start, end,
                                  arrowstyle='->',
                                  mutation_scale=15,
                                  linewidth=1.5,
                                  color='darkgreen',
                                  connectionstyle='arc3,rad=0.2')
            ax.add_patch(arrow)
            mid_x, mid_y = (start[0] + end[0])/2, (start[1] + end[1])/2
            ax.text(mid_x, mid_y-0.3, label, ha='center', va='center',
                   fontsize=8, bbox=dict(boxstyle='round,pad=0.2', facecolor='white', edgecolor='darkgreen'))
    
    ax.set_title('DFD Level 0 - Context Diagram\nITR API System', 
                fontsize=16, fontweight='bold', pad=20)
    
    plt.tight_layout()
    return fig

def generate_dfd_level1():
    """Generate DFD Level 1"""
    fig, ax = plt.subplots(figsize=(20, 14))
    ax.set_xlim(0, 20)
    ax.set_ylim(0, 14)
    ax.axis('off')
    
    # External entities
    user_pos = (1, 7)
    gateway_pos = (19, 7)
    admin_pos = (10, 12.5)
    
    for name, pos in [('User', user_pos), ('Payment Gateway', gateway_pos), ('Admin', admin_pos)]:
        box = FancyBboxPatch((pos[0]-1, pos[1]-0.5), 2, 1,
                            boxstyle="round,pad=0.1",
                            facecolor='#FFF9C4',
                            edgecolor='orange',
                            linewidth=1.5)
        ax.add_patch(box)
        ax.text(pos[0], pos[1], name, ha='center', va='center', fontsize=10, fontweight='bold')
    
    # Processes
    processes = [
        ('1.0\nAuthentication', 4, 10, '#E3F2FD'),
        ('2.0\nPersonal\nDetails', 4, 7, '#E8F5E9'),
        ('3.0\nDocument\nUpload', 4, 4, '#E8F5E9'),
        ('4.0\nPayment\nProcessing', 10, 10, '#FCE4EC'),
        ('5.0\nITR Filing', 10, 7, '#FFF3E0'),
        ('6.0\nStatus\nTracking', 10, 4, '#E0F2F1'),
        ('7.0\nConcern\nManagement', 16, 7, '#E0F2F1')
    ]
    
    process_boxes = {}
    for name, x, y, color in processes:
        box = FancyBboxPatch((x-1, y-0.8), 2, 1.6,
                            boxstyle="round,pad=0.1",
                            facecolor=color,
                            edgecolor='darkblue',
                            linewidth=1.5)
        ax.add_patch(box)
        ax.text(x, y, name, ha='center', va='center', fontsize=9, fontweight='bold')
        process_boxes[name] = (x, y)
    
    # Data stores
    stores = [
        ('D1\nusers', 6.5, 10.5),
        ('D2\npersonal_details', 6.5, 7.5),
        ('D3\ndocument_details', 6.5, 4.5),
        ('D4\npayment_info', 12.5, 10.5),
        ('D5\nitr_detail', 12.5, 7.5),
        ('D6\nitr_order_status', 12.5, 4.5),
        ('D7\nitr_order_concerns', 16, 4.5)
    ]
    
    for name, x, y in stores:
        # Draw open rectangle for data store
        ax.add_patch(Rectangle((x-0.6, y-0.4), 1.2, 0.8,
                              facecolor='white',
                              edgecolor='black',
                              linewidth=1.5))
        ax.text(x, y, name, ha='center', va='center', fontsize=8, fontweight='bold')
    
    # Key data flows (simplified for clarity)
    key_flows = [
        (user_pos, process_boxes['1.0\nAuthentication'], 'Login Request'),
        (process_boxes['1.0\nAuthentication'], user_pos, 'Token'),
        (user_pos, process_boxes['2.0\nPersonal\nDetails'], 'Personal Info'),
        (user_pos, process_boxes['3.0\nDocument\nUpload'], 'Documents'),
        (user_pos, process_boxes['4.0\nPayment\nProcessing'], 'Payment Request'),
        (process_boxes['4.0\nPayment\nProcessing'], gateway_pos, 'Payment Init'),
        (gateway_pos, process_boxes['4.0\nPayment\nProcessing'], 'Payment Status'),
        (process_boxes['5.0\nITR Filing'], user_pos, 'ITR Details'),
        (process_boxes['6.0\nStatus\nTracking'], user_pos, 'Status Updates'),
        (user_pos, process_boxes['7.0\nConcern\nManagement'], 'Concern'),
        (admin_pos, process_boxes['7.0\nConcern\nManagement'], 'Resolution'),
    ]
    
    for start, end, label in key_flows:
        arrow = FancyArrowPatch(start, end,
                              arrowstyle='->',
                              mutation_scale=12,
                              linewidth=1.2,
                              color='darkgreen',
                              connectionstyle='arc3,rad=0.1')
        ax.add_patch(arrow)
        mid_x, mid_y = (start[0] + end[0])/2, (start[1] + end[1])/2
        ax.text(mid_x, mid_y-0.2, label, ha='center', va='center',
               fontsize=7, bbox=dict(boxstyle='round,pad=0.1', facecolor='white', edgecolor='darkgreen'))
    
    ax.set_title('DFD Level 1 - System Processes\nITR API Data Flow', 
                fontsize=16, fontweight='bold', pad=20)
    
    # Add legend
    legend_elements = [
        mpatches.Patch(facecolor='#FFF9C4', edgecolor='orange', label='External Entity'),
        mpatches.Patch(facecolor='#E3F2FD', edgecolor='darkblue', label='Process'),
        Rectangle((0, 0), 1, 1, facecolor='white', edgecolor='black', label='Data Store')
    ]
    ax.legend(handles=legend_elements, loc='lower left', fontsize=9)
    
    plt.tight_layout()
    return fig

def generate_architecture_diagram():
    """Generate Architectural Table Relationship Diagram"""
    fig, ax = plt.subplots(figsize=(20, 16))
    ax.set_xlim(0, 20)
    ax.set_ylim(0, 16)
    ax.axis('off')
    
    # Group tables by functional area
    groups = {
        'User Management': {
            'tables': ['users', 'personal_details', 'document_details'],
            'pos': (3, 13),
            'color': COLORS['user_data']
        },
        'ITR Management': {
            'tables': ['itr_detail', 'itr_source', 'itr_packages'],
            'pos': (10, 13),
            'color': COLORS['itr']
        },
        'Payment System': {
            'tables': ['payment_info', 'payment_additional_fees'],
            'pos': (17, 13),
            'color': COLORS['payment']
        },
        'Status & Tracking': {
            'tables': ['itr_order_status', 'itr_order_concerns', 'itr_assignments'],
            'pos': (6.5, 6),
            'color': COLORS['status']
        },
        'Catalog': {
            'tables': ['services'],
            'pos': (13.5, 6),
            'color': COLORS['catalog']
        }
    }
    
    table_positions = {}
    
    # Draw groups and tables
    for group_name, group_info in groups.items():
        tables = group_info['tables']
        base_x, base_y = group_info['pos']
        color = group_info['color']
        
        # Draw group box
        num_tables = len(tables)
        group_width = 3.5
        group_height = num_tables * 1.2 + 0.8
        
        group_box = FancyBboxPatch((base_x - group_width/2, base_y - group_height/2),
                                  group_width, group_height,
                                  boxstyle="round,pad=0.2",
                                  facecolor=color,
                                  edgecolor='darkblue',
                                  linewidth=2,
                                  alpha=0.3)
        ax.add_patch(group_box)
        
        # Group title
        ax.text(base_x, base_y + group_height/2 - 0.3, group_name,
               ha='center', va='top', fontsize=11, fontweight='bold',
               bbox=dict(boxstyle='round,pad=0.2', facecolor='white', edgecolor='darkblue'))
        
        # Draw tables in group
        y_offset = base_y + group_height/2 - 0.8
        for i, table_name in enumerate(tables):
            table_info = TABLES[table_name]
            table_x = base_x
            table_y = y_offset - i * 1.2
            
            # Table box
            table_box = FancyBboxPatch((table_x - 1.4, table_y - 0.4), 2.8, 0.8,
                                      boxstyle="round,pad=0.1",
                                      facecolor='white',
                                      edgecolor='black',
                                      linewidth=1.5)
            ax.add_patch(table_box)
            
            # Table name
            ax.text(table_x, table_y, table_name, ha='center', va='center',
                   fontsize=9, fontweight='bold')
            
            # Show key relationships
            fk_info = []
            for fk_field, ref_table, ref_field in table_info.get('fk', []):
                fk_info.append(f"{fk_field}→{ref_table}")
            
            if fk_info:
                ax.text(table_x, table_y - 0.25, ', '.join(fk_info[:2]),
                       ha='center', va='top', fontsize=7, style='italic', color='blue')
            
            table_positions[table_name] = (table_x, table_y)
    
    # Draw relationships between tables
    relationships = [
        ('users', 'personal_details'),
        ('users', 'document_details'),
        ('users', 'itr_detail'),
        ('users', 'payment_info'),
        ('users', 'itr_order_status'),
        ('users', 'itr_order_concerns'),
        ('itr_detail', 'itr_source'),
        ('itr_detail', 'itr_order_status'),
        ('itr_detail', 'itr_assignments'),
        ('itr_packages', 'payment_info'),
        ('itr_order_status', 'itr_order_concerns'),
    ]
    
    for from_table, to_table in relationships:
        if from_table in table_positions and to_table in table_positions:
            x1, y1 = table_positions[from_table]
            x2, y2 = table_positions[to_table]
            
            # Draw arrow
            arrow = FancyArrowPatch((x1, y1-0.4), (x2, y2+0.4),
                                  arrowstyle='->',
                                  mutation_scale=15,
                                  linewidth=1.2,
                                  color='darkred',
                                  connectionstyle='arc3,rad=0.2',
                                  alpha=0.6)
            ax.add_patch(arrow)
    
    ax.set_title('Architectural Table Relationship Diagram\nITR API Database Structure', 
                fontsize=16, fontweight='bold', pad=20)
    
    # Add legend
    legend_text = "Legend:\n• Boxes represent database tables\n• Arrows show foreign key relationships\n• Colors indicate functional groups"
    ax.text(18, 2, legend_text, ha='left', va='bottom', fontsize=9,
           bbox=dict(boxstyle='round,pad=0.5', facecolor='#F5F5F5', edgecolor='gray'))
    
    plt.tight_layout()
    return fig

def generate_flowchart_user_journey():
    """Generate User Journey Flowchart"""
    fig, ax = plt.subplots(figsize=(18, 14))
    ax.set_xlim(0, 18)
    ax.set_ylim(0, 14)
    ax.axis('off')
    
    # Define flowchart elements
    elements = [
        ('Start', 9, 13, 'ellipse', '#E3F2FD'),
        ('Signup/Login', 9, 11.5, 'box', '#E8F5E9'),
        ('Add Personal Details', 3, 10, 'box', '#E8F5E9'),
        ('Upload Documents', 9, 10, 'box', '#E8F5E9'),
        ('Select Package', 15, 10, 'box', '#FFF3E0'),
        ('Initiate Payment', 9, 8.5, 'box', '#FCE4EC'),
        ('Payment Success?', 9, 7, 'diamond', '#FFE082'),
        ('Payment Failed', 9, 5.5, 'box', '#EF5350'),
        ('Payment Gateway', 15, 7, 'box', '#B39DDB'),
        ('ITR Assignment', 3, 7, 'box', '#E0F2F1'),
        ('Status Updates', 3, 5.5, 'box', '#E0F2F1'),
        ('Raise Concern?', 3, 4, 'diamond', '#FFE082'),
        ('Resolve Concern', 6, 4, 'box', '#E0F2F1'),
        ('ITR Filed', 9, 4, 'box', '#C8E6C9'),
        ('End', 9, 2.5, 'ellipse', '#E3F2FD'),
    ]
    
    positions = {}
    for name, x, y, shape, color in elements:
        if shape == 'ellipse':
            ellipse = mpatches.Ellipse((x, y), 2, 0.8, facecolor=color, edgecolor='black', linewidth=1.5)
            ax.add_patch(ellipse)
            ax.text(x, y, name, ha='center', va='center', fontsize=9, fontweight='bold')
        elif shape == 'diamond':
            diamond = mpatches.RegularPolygon((x, y), 4, radius=0.8, orientation=0.785, 
                                            facecolor=color, edgecolor='black', linewidth=1.5)
            ax.add_patch(diamond)
            ax.text(x, y, name, ha='center', va='center', fontsize=9, fontweight='bold', wrap=True)
        else:
            box = FancyBboxPatch((x-1, y-0.4), 2, 0.8, boxstyle="round,pad=0.1",
                               facecolor=color, edgecolor='black', linewidth=1.5)
            ax.add_patch(box)
            ax.text(x, y, name, ha='center', va='center', fontsize=9, fontweight='bold', wrap=True)
        positions[name] = (x, y)
    
    # Draw arrows
    arrows = [
        ('Start', 'Signup/Login'),
        ('Signup/Login', 'Add Personal Details'),
        ('Add Personal Details', 'Upload Documents'),
        ('Upload Documents', 'Select Package'),
        ('Select Package', 'Initiate Payment'),
        ('Initiate Payment', 'Payment Success?'),
        ('Payment Success?', 'Payment Gateway', 'No'),
        ('Payment Gateway', 'Payment Success?'),
        ('Payment Success?', 'ITR Assignment', 'Yes'),
        ('ITR Assignment', 'Status Updates'),
        ('Status Updates', 'Raise Concern?'),
        ('Raise Concern?', 'Resolve Concern', 'Yes'),
        ('Resolve Concern', 'Status Updates'),
        ('Raise Concern?', 'ITR Filed', 'No'),
        ('Payment Failed', 'Initiate Payment'),
        ('ITR Filed', 'End'),
    ]
    
    for arrow_info in arrows:
        from_name = arrow_info[0]
        to_name = arrow_info[1]
        label = arrow_info[2] if len(arrow_info) > 2 else ''
        
        if from_name in positions and to_name in positions:
            start = positions[from_name]
            end = positions[to_name]
            
            # Adjust start/end points for shapes
            if from_name in ['Payment Success?', 'Raise Concern?']:
                # Diamond - exit from right or bottom
                if abs(end[0] - start[0]) > abs(end[1] - start[1]):
                    start = (start[0] + 0.6, start[1])
                else:
                    start = (start[0], start[1] - 0.6)
            else:
                if abs(end[0] - start[0]) > abs(end[1] - start[1]):
                    start = (start[0] + (1 if end[0] > start[0] else -1), start[1])
                else:
                    start = (start[0], start[1] - 0.4)
            
            if to_name in ['Payment Success?', 'Raise Concern?']:
                if abs(end[0] - start[0]) > abs(end[1] - start[1]):
                    end = (end[0] - 0.6, end[1])
                else:
                    end = (end[0], end[1] + 0.6)
            else:
                if abs(end[0] - start[0]) > abs(end[1] - start[1]):
                    end = (end[0] - (1 if end[0] > start[0] else -1), end[1])
                else:
                    end = (end[0], end[1] + 0.4)
            
            arrow = FancyArrowPatch(start, end, arrowstyle='->', mutation_scale=15,
                                  linewidth=1.5, color='darkblue', connectionstyle='arc3,rad=0.1')
            ax.add_patch(arrow)
            
            if label:
                mid_x, mid_y = (start[0] + end[0])/2, (start[1] + end[1])/2
                ax.text(mid_x, mid_y - 0.2, label, ha='center', va='center', fontsize=8,
                       bbox=dict(boxstyle='round,pad=0.2', facecolor='yellow', edgecolor='orange', alpha=0.7))
    
    ax.set_title('User Journey Flowchart\nITR Filing Process', 
                fontsize=16, fontweight='bold', pad=20)
    
    plt.tight_layout()
    return fig

def generate_flowchart_payment_process():
    """Generate Payment Process Flowchart"""
    fig, ax = plt.subplots(figsize=(16, 12))
    ax.set_xlim(0, 16)
    ax.set_ylim(0, 12)
    ax.axis('off')
    
    elements = [
        ('Start Payment', 8, 11, 'ellipse', '#E3F2FD'),
        ('Get Payment Info', 8, 9.5, 'box', '#FCE4EC'),
        ('Calculate Amount', 8, 8, 'box', '#FCE4EC'),
        ('Initiate Payment', 8, 6.5, 'box', '#FCE4EC'),
        ('Redirect to Gateway', 12, 6.5, 'box', '#B39DDB'),
        ('User Pays', 12, 5, 'box', '#B39DDB'),
        ('Payment Success?', 12, 3.5, 'diamond', '#FFE082'),
        ('Success Response', 8, 3.5, 'box', '#C8E6C9'),
        ('Update Status', 8, 2, 'box', '#E0F2F1'),
        ('Webhook Received', 4, 5, 'box', '#B39DDB'),
        ('Verify Payment', 4, 3.5, 'box', '#B39DDB'),
        ('Update Database', 4, 2, 'box', '#C8E6C9'),
        ('Payment Failed', 12, 1, 'box', '#EF5350'),
        ('End', 8, 0.5, 'ellipse', '#E3F2FD'),
    ]
    
    positions = {}
    for name, x, y, shape, color in elements:
        if shape == 'ellipse':
            ellipse = mpatches.Ellipse((x, y), 2, 0.6, facecolor=color, edgecolor='black', linewidth=1.5)
            ax.add_patch(ellipse)
            ax.text(x, y, name, ha='center', va='center', fontsize=9, fontweight='bold')
        elif shape == 'diamond':
            diamond = mpatches.RegularPolygon((x, y), 4, radius=0.7, orientation=0.785,
                                            facecolor=color, edgecolor='black', linewidth=1.5)
            ax.add_patch(diamond)
            ax.text(x, y, name, ha='center', va='center', fontsize=8, fontweight='bold', wrap=True)
        else:
            box = FancyBboxPatch((x-1, y-0.3), 2, 0.6, boxstyle="round,pad=0.1",
                               facecolor=color, edgecolor='black', linewidth=1.5)
            ax.add_patch(box)
            ax.text(x, y, name, ha='center', va='center', fontsize=9, fontweight='bold', wrap=True)
        positions[name] = (x, y)
    
    arrows = [
        ('Start Payment', 'Get Payment Info'),
        ('Get Payment Info', 'Calculate Amount'),
        ('Calculate Amount', 'Initiate Payment'),
        ('Initiate Payment', 'Redirect to Gateway'),
        ('Redirect to Gateway', 'User Pays'),
        ('User Pays', 'Payment Success?'),
        ('Payment Success?', 'Success Response', 'Yes'),
        ('Payment Success?', 'Payment Failed', 'No'),
        ('Success Response', 'Update Status'),
        ('Update Status', 'End'),
        ('Payment Failed', 'End'),
        ('User Pays', 'Webhook Received'),
        ('Webhook Received', 'Verify Payment'),
        ('Verify Payment', 'Update Database'),
        ('Update Database', 'Update Status'),
    ]
    
    for arrow_info in arrows:
        from_name = arrow_info[0]
        to_name = arrow_info[1]
        label = arrow_info[2] if len(arrow_info) > 2 else ''
        
        if from_name in positions and to_name in positions:
            start = positions[from_name]
            end = positions[to_name]
            
            if from_name == 'Payment Success?':
                start = (start[0] - 0.5, start[1]) if end[0] < start[0] else (start[0] + 0.5, start[1])
            
            arrow = FancyArrowPatch(start, end, arrowstyle='->', mutation_scale=12,
                                  linewidth=1.2, color='darkgreen', connectionstyle='arc3,rad=0.1')
            ax.add_patch(arrow)
            
            if label:
                mid_x, mid_y = (start[0] + end[0])/2, (start[1] + end[1])/2
                ax.text(mid_x, mid_y - 0.15, label, ha='center', va='center', fontsize=7,
                       bbox=dict(boxstyle='round,pad=0.1', facecolor='yellow', edgecolor='orange', alpha=0.7))
    
    ax.set_title('Payment Process Flowchart\nPayment Gateway Integration', 
                fontsize=16, fontweight='bold', pad=20)
    
    plt.tight_layout()
    return fig

def generate_api_documentation_page():
    """Generate API Documentation Summary Page"""
    fig, ax = plt.subplots(figsize=(11, 8.5))
    ax.axis('off')
    
    y_pos = 0.95
    ax.text(0.5, y_pos, 'API Documentation Summary', ha='center', va='top',
           fontsize=20, fontweight='bold', transform=ax.transAxes)
    
    y_pos = 0.88
    
    api_groups = [
        ('Authentication APIs', [
            'POST /auth/signup.php - User Registration',
            'POST /auth/login.php - User Login (Returns JWT Token)',
            'POST /auth/refresh_token.php - Refresh JWT Token',
            'POST /auth/forget_password.php - Password Reset'
        ]),
        ('Personal Details APIs', [
            'POST /itrdetails/personal_details.php - Add/Update Personal Details',
            'GET /itrdetails/get_personal_detail.php - Get Personal Details'
        ]),
        ('Document Management APIs', [
            'POST /itrdetails/add_documents.php - Upload Document',
            'POST /itrdetails/save_documents.php - Save Document Metadata',
            'GET /itrdetails/get_documents.php - Get User Documents',
            'POST /itrdetails/delete_document.php - Delete Document',
            'GET /itrdetails/download_document.php - Download Document'
        ]),
        ('Payment APIs', [
            'GET /payment/get_payment_info.php - Get Payment Information',
            'POST /payment/initiate_payment.php - Initiate Payment',
            'GET /payment/get_payment_status.php - Get Payment Status',
            'GET /payment/get_payment_history.php - Get Payment History',
            'POST /payment/verify_payment.php - Verify Payment',
            'POST /payment/webhook.php - Payment Webhook',
            'GET /payment/success.php - Payment Success Page'
        ]),
        ('ITR Management APIs', [
            'GET /get_itrbyuser.php - Get ITR by User ID',
            'GET /get_itrbyitrid.php - Get ITR by ITR ID',
            'GET /package/getPackages.php - Get Available Packages'
        ]),
        ('Status Tracking APIs', [
            'GET /itr_status/get_order_status.php - Get Order Status',
            'POST /itr_status/raise_concern.php - Raise Concern',
            'POST /itr_status/resolve_concern.php - Resolve Concern'
        ]),
        ('Admin Panel APIs', [
            'GET /admin/dashboard.php - Dashboard Statistics',
            'GET /admin/users.php - Get Users List',
            'GET /admin/orders.php - Get Orders List',
            'GET /admin/payments.php - Get Payments List',
            'GET /admin/itrs.php - Get ITRs List',
            'GET /admin/concerns.php - Get Concerns List',
            'GET /admin/analytics.php - Get Analytics Data',
            'POST /admin/assign_itr.php - Assign ITR to Professional',
            'GET /admin/get_assignments.php - Get Assignments',
            'POST /admin/update_assignment.php - Update Assignment'
        ])
    ]
    
    for group_name, apis in api_groups:
        ax.text(0.05, y_pos, group_name, ha='left', va='top',
               fontsize=12, fontweight='bold', transform=ax.transAxes)
        y_pos -= 0.05
        
        for api in apis:
            ax.text(0.08, y_pos, f'• {api}', ha='left', va='top',
                   fontsize=9, transform=ax.transAxes, family='monospace')
            y_pos -= 0.04
        
        y_pos -= 0.02
    
    ax.text(0.5, 0.02, f'Generated: {datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}',
           ha='center', va='bottom', fontsize=8, transform=ax.transAxes, style='italic')
    
    plt.tight_layout()
    return fig

def generate_system_architecture():
    """Generate System Architecture Diagram"""
    fig, ax = plt.subplots(figsize=(18, 14))
    ax.set_xlim(0, 18)
    ax.set_ylim(0, 14)
    ax.axis('off')
    
    # Layers
    layers = [
        ('Client Layer', 9, 12.5, 16, 1, '#E3F2FD'),
        ('API Gateway Layer', 9, 10.5, 16, 1, '#F3E5F5'),
        ('Business Logic Layer', 9, 8, 16, 1.5, '#E8F5E9'),
        ('Data Access Layer', 9, 5.5, 16, 1, '#FFF3E0'),
        ('Database Layer', 9, 3.5, 16, 1, '#FCE4EC'),
    ]
    
    for name, x, y, width, height, color in layers:
        box = FancyBboxPatch((x - width/2, y - height/2), width, height,
                           boxstyle="round,pad=0.2", facecolor=color, edgecolor='darkblue', linewidth=2, alpha=0.7)
        ax.add_patch(box)
        ax.text(x, y, name, ha='center', va='center', fontsize=12, fontweight='bold',
               bbox=dict(boxstyle='round,pad=0.3', facecolor='white', edgecolor='darkblue'))
    
    # Client Layer Components
    clients = ['Web Browser', 'Mobile App', 'Admin Panel']
    for i, client in enumerate(clients):
        x = 3 + i * 4
        y = 12.5
        box = FancyBboxPatch((x - 1.5, y - 0.3), 3, 0.6, boxstyle="round,pad=0.1",
                           facecolor='white', edgecolor='blue', linewidth=1.5)
        ax.add_patch(box)
        ax.text(x, y, client, ha='center', va='center', fontsize=9)
    
    # API Gateway Components
    apis = ['Auth API', 'ITR API', 'Payment API', 'Admin API']
    for i, api in enumerate(apis):
        x = 2 + i * 3.5
        y = 10.5
        box = FancyBboxPatch((x - 1.2, y - 0.3), 2.4, 0.6, boxstyle="round,pad=0.1",
                           facecolor='white', edgecolor='purple', linewidth=1.5)
        ax.add_patch(box)
        ax.text(x, y, api, ha='center', va='center', fontsize=8)
    
    # Business Logic Components
    services = ['Authentication\nService', 'ITR Service', 'Payment\nService', 'Admin\nService', 'Status\nService']
    for i, service in enumerate(services):
        x = 2 + i * 3
        y = 8
        box = FancyBboxPatch((x - 1, y - 0.4), 2, 0.8, boxstyle="round,pad=0.1",
                           facecolor='white', edgecolor='green', linewidth=1.5)
        ax.add_patch(box)
        ax.text(x, y, service, ha='center', va='center', fontsize=8)
    
    # Data Access Components
    daos = ['User DAO', 'ITR DAO', 'Payment DAO', 'Status DAO']
    for i, dao in enumerate(daos):
        x = 3 + i * 3
        y = 5.5
        box = FancyBboxPatch((x - 1, y - 0.3), 2, 0.6, boxstyle="round,pad=0.1",
                           facecolor='white', edgecolor='orange', linewidth=1.5)
        ax.add_patch(box)
        ax.text(x, y, dao, ha='center', va='center', fontsize=8)
    
    # Database Components
    dbs = ['MySQL Database']
    x = 9
    y = 3.5
    box = FancyBboxPatch((x - 2, y - 0.3), 4, 0.6, boxstyle="round,pad=0.1",
                       facecolor='white', edgecolor='red', linewidth=1.5)
    ax.add_patch(box)
    ax.text(x, y, dbs[0], ha='center', va='center', fontsize=10, fontweight='bold')
    
    # External Services
    ext_services = ['Payment Gateway\n(PayTM/Razorpay)', 'Email Service\n(SMTP)']
    for i, ext in enumerate(ext_services):
        x = 2 + i * 5
        y = 1.5
        box = FancyBboxPatch((x - 1.5, y - 0.3), 3, 0.6, boxstyle="round,pad=0.1",
                           facecolor='#FFF9C4', edgecolor='orange', linewidth=1.5)
        ax.add_patch(box)
        ax.text(x, y, ext, ha='center', va='center', fontsize=8)
    
    # Draw arrows between layers
    for i in range(1, len(layers)):
        start_y = layers[i-1][2] - layers[i-1][4]/2
        end_y = layers[i][2] + layers[i][4]/2
        
        for j in range(3):
            x = 5 + j * 4
            arrow = FancyArrowPatch((x, start_y), (x, end_y), arrowstyle='->',
                                  mutation_scale=15, linewidth=1.5, color='gray', alpha=0.5)
            ax.add_patch(arrow)
    
    ax.set_title('System Architecture Diagram\nITR API System Layers', 
                fontsize=16, fontweight='bold', pad=20)
    
    plt.tight_layout()
    return fig

def generate_database_schema_page():
    """Generate Database Schema Documentation Page"""
    fig, ax = plt.subplots(figsize=(11, 8.5))
    ax.axis('off')
    
    y_pos = 0.95
    ax.text(0.5, y_pos, 'Database Schema Documentation', ha='center', va='top',
           fontsize=20, fontweight='bold', transform=ax.transAxes)
    
    y_pos = 0.88
    
    schema_info = [
        ('Core Tables', [
            'users - User authentication and profile information',
            '  • UserId (PK), Email, Password, Role, IsActive, ...'
        ]),
        ('User Data Tables', [
            'personal_details - Personal information for ITR filing',
            '  • id (PK), UserId (FK), PANNumber, FirstName, LastName, ...',
            'document_details - Uploaded document metadata',
            '  • id (PK), UserId (FK), PanNumber, name, type, fileName, ...'
        ]),
        ('ITR Management Tables', [
            'itr_detail - ITR filing records',
            '  • id (PK), userId (FK), panNumber, financialYear, status, ...',
            'itr_source - ITR income sources',
            '  • id (PK), itrId (FK), sourceType, sourceName, amount, ...',
            'itr_packages - Available ITR packages/pricing',
            '  • id (PK), packagename, price, title1, description1, ...'
        ]),
        ('Payment Tables', [
            'payment_info - Payment transactions',
            '  • id (PK), payment_id, user_id (FK), package_id (FK), order_id, ...',
            'payment_additional_fees - Configurable additional fees',
            '  • id (PK), fee_name, fee_amount, display_order, is_active, ...'
        ]),
        ('Status & Tracking Tables', [
            'itr_order_status - Order status tracking',
            '  • id (PK), order_id, itr_id (FK), user_id (FK), status_step, ...',
            'itr_order_concerns - Concerns/issues for orders',
            '  • id (PK), status_id (FK), user_id (FK), concern_type, concern_text, ...',
            'itr_assignments - ITR assignments to professionals',
            '  • id (PK), itr_id (FK), user_id (FK), professional_id (FK), status, ...'
        ]),
        ('Catalog Tables', [
            'services - Available services',
            '  • id (PK), Name, CreatedAt'
        ]),
        ('User Roles', [
            'Role ENUM: CLIENT, ADMIN, ACCOUNTANT, CA',
            'CLIENT - Regular users filing ITR',
            'ADMIN - System administrators',
            'ACCOUNTANT - Tax professionals/accountants',
            'CA - Chartered Accountants'
        ])
    ]
    
    for group_name, items in schema_info:
        ax.text(0.05, y_pos, group_name, ha='left', va='top',
               fontsize=12, fontweight='bold', transform=ax.transAxes)
        y_pos -= 0.04
        
        for item in items:
            ax.text(0.08, y_pos, item, ha='left', va='top',
                   fontsize=9, transform=ax.transAxes, family='monospace')
            y_pos -= 0.035
        
        y_pos -= 0.02
    
    ax.text(0.5, 0.02, f'Generated: {datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}',
           ha='center', va='bottom', fontsize=8, transform=ax.transAxes, style='italic')
    
    plt.tight_layout()
    return fig

def create_pdf():
    """Create PDF with all diagrams"""
    pdf_filename = 'ITR_API_Diagrams.pdf'
    
    with PdfPages(pdf_filename) as pdf:
        # Title page
        fig = plt.figure(figsize=(11, 8.5))
        ax = fig.add_subplot(111)
        ax.axis('off')
        ax.text(0.5, 0.7, 'ITR API System', ha='center', va='center',
               fontsize=32, fontweight='bold', transform=ax.transAxes)
        ax.text(0.5, 0.6, 'Database Documentation', ha='center', va='center',
               fontsize=24, transform=ax.transAxes)
        ax.text(0.5, 0.4, 'Entity Relationship Diagram\nData Flow Diagram\nArchitecture Diagram',
               ha='center', va='center', fontsize=16, transform=ax.transAxes)
        ax.text(0.5, 0.1, 'Generated: ' + datetime.datetime.now().strftime('%Y-%m-%d'),
               ha='center', va='center', fontsize=12, transform=ax.transAxes)
        pdf.savefig(fig, bbox_inches='tight')
        plt.close(fig)
        
        # Table of contents
        fig = plt.figure(figsize=(11, 8.5))
        ax = fig.add_subplot(111)
        ax.axis('off')
        ax.text(0.5, 0.9, 'Table of Contents', ha='center', va='top',
               fontsize=20, fontweight='bold', transform=ax.transAxes)
        contents = [
            '1. Entity Relationship Diagram (ERD)',
            '2. Data Flow Diagram - Level 0 (Context Diagram)',
            '3. Data Flow Diagram - Level 1 (System Processes)',
            '4. User Journey Flowchart',
            '5. Payment Process Flowchart',
            '6. System Architecture Diagram',
            '7. Architectural Table Relationship Diagram',
            '8. Database Schema Documentation',
            '9. API Documentation Summary'
        ]
        y_pos = 0.7
        for content in contents:
            ax.text(0.1, y_pos, content, ha='left', va='top',
                   fontsize=14, transform=ax.transAxes)
            y_pos -= 0.1
        pdf.savefig(fig, bbox_inches='tight')
        plt.close(fig)
        
        # ER Diagram
        print("Generating ER Diagram...")
        fig = generate_er_diagram()
        pdf.savefig(fig, bbox_inches='tight')
        plt.close(fig)
        
        # DFD Level 0
        print("Generating DFD Level 0...")
        fig = generate_dfd_level0()
        pdf.savefig(fig, bbox_inches='tight')
        plt.close(fig)
        
        # DFD Level 1
        print("Generating DFD Level 1...")
        fig = generate_dfd_level1()
        pdf.savefig(fig, bbox_inches='tight')
        plt.close(fig)
        
        # User Journey Flowchart
        print("Generating User Journey Flowchart...")
        fig = generate_flowchart_user_journey()
        pdf.savefig(fig, bbox_inches='tight')
        plt.close(fig)
        
        # Payment Process Flowchart
        print("Generating Payment Process Flowchart...")
        fig = generate_flowchart_payment_process()
        pdf.savefig(fig, bbox_inches='tight')
        plt.close(fig)
        
        # System Architecture Diagram
        print("Generating System Architecture Diagram...")
        fig = generate_system_architecture()
        pdf.savefig(fig, bbox_inches='tight')
        plt.close(fig)
        
        # Architecture Diagram
        print("Generating Architectural Table Relationship Diagram...")
        fig = generate_architecture_diagram()
        pdf.savefig(fig, bbox_inches='tight')
        plt.close(fig)
        
        # Database Schema Documentation
        print("Generating Database Schema Documentation...")
        fig = generate_database_schema_page()
        pdf.savefig(fig, bbox_inches='tight')
        plt.close(fig)
        
        # API Documentation
        print("Generating API Documentation...")
        fig = generate_api_documentation_page()
        pdf.savefig(fig, bbox_inches='tight')
        plt.close(fig)
    
    print(f"\n✓ PDF generated successfully: {pdf_filename}")
    return pdf_filename

if __name__ == '__main__':
    import datetime
    create_pdf()

