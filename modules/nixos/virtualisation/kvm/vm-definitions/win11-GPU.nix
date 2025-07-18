{ pkgs
, ...
}:
pkgs.writeText "win11-GPU.xml" ''
    <domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
    	<name>win11-GPU</name>
    	<uuid>456cf1dd-e827-4162-b1d9-14dd038f963d</uuid>
    	<metadata>
    		<libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
    			<libosinfo:os id="http://microsoft.com/win/11"/>
    		</libosinfo:libosinfo>
    	</metadata>
    	<memory unit='KiB'>32804864</memory>
    	<currentMemory unit='KiB'>32804864</currentMemory>
    	<memoryBacking>
    		<source type='memfd'/>
    		<access mode='shared'/>
    	</memoryBacking>
    	<vcpu placement='static'>12</vcpu>
    	<cputune>
    		<vcpupin vcpu='0' cpuset='4'/>
    		<vcpupin vcpu='1' cpuset='5'/>
    		<vcpupin vcpu='2' cpuset='6'/>
    		<vcpupin vcpu='3' cpuset='7'/>
    		<vcpupin vcpu='4' cpuset='8'/>
    		<vcpupin vcpu='5' cpuset='9'/>
    		<vcpupin vcpu='6' cpuset='10'/>
    		<vcpupin vcpu='7' cpuset='11'/>
    		<vcpupin vcpu='8' cpuset='12'/>
    		<vcpupin vcpu='9' cpuset='13'/>
    		<vcpupin vcpu='10' cpuset='14'/>
    		<vcpupin vcpu='11' cpuset='15'/>
    	</cputune>
    	<os firmware='efi'>
    		<type arch='x86_64' machine='pc-q35-9.2'>hvm</type>
    		<firmware>
    			<feature enabled='no' name='enrolled-keys'/>
    			<feature enabled='yes' name='secure-boot'/>
    		</firmware>
    		<loader readonly='yes' secure='yes' type='pflash' format='raw'>${pkgs.qemu_kvm}/share/qemu/edk2-x86_64-secure-code.fd</loader>
    		<nvram template='${pkgs.qemu_kvm}/share/qemu/edk2-i386-vars.fd' templateFormat='raw' format='raw'>/var/lib/libvirt/qemu/nvram/win11-GPU_VARS.fd</nvram>
    		<boot dev='hd'/>
    		<smbios mode='host'/>
    	</os>
    	<features>
    		<acpi/>
    		<apic/>
    		<hyperv mode='custom'>
    			<relaxed state='on'/>
    			<vapic state='on'/>
    			<spinlocks state='on' retries='8191'/>
    			<vpindex state='on'/>
    			<runtime state='on'/>
    			<synic state='on'/>
    			<stimer state='on'/>
    			<vendor_id state='on' value='something'/>
    			<frequencies state='on'/>
    			<tlbflush state='on'/>
    			<ipi state='on'/>
    			<evmcs state='on'/>
    			<avic state='on'/>
    		</hyperv>
    		<kvm>
    			<hidden state='on'/>
    		</kvm>
    		<vmport state='off'/>
    		<smm state='on'/>
    	</features>
    	<cpu mode='host-passthrough' check='none' migratable='on'>
    		<topology sockets='1' dies='1' clusters='1' cores='6' threads='2'/>
    		<cache mode='passthrough'/>
  			<features>
  			  <feature policy='disable' name='kvm'/>
  			</features>
    		<maxphysaddr mode='emulate'/>
    	</cpu>
    	<clock offset='localtime'>
    		<timer name='rtc' tickpolicy='catchup'/>
    		<timer name='pit' tickpolicy='delay'/>
    		<timer name='hpet' present='no'/>
    		<timer name='hypervclock' present='yes'/>
    	</clock>
    	<on_poweroff>destroy</on_poweroff>
    	<on_reboot>restart</on_reboot>
    	<on_crash>destroy</on_crash>
    	<pm>
    		<suspend-to-mem enabled='no'/>
    		<suspend-to-disk enabled='no'/>
    	</pm>
    	<devices>
    		<emulator>/run/libvirt/nix-emulators/qemu-system-x86_64</emulator>
    		<disk type='file' device='disk'>
    			<driver name='qemu' type='raw'/>
    			<source file='/var/lib/libvirt/images/win11-GPU.img'/>
    			<target dev='vda' bus='virtio'/>
    			<address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x0'/>
    		</disk>
    		<disk type='file' device='cdrom'>
    			<driver name='qemu' type='raw'/>
    			<source file='/var/lib/libvirt/isos/virtio-win-0.1.271.iso'/>
    			<target dev='sda' bus='sata'/>
    			<readonly/>
    			<address type='drive' controller='0' bus='0' target='0' unit='0'/>
    		</disk>
    		<controller type='usb' index='0' model='qemu-xhci' ports='15'>
    			<address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x0'/>
    		</controller>
    		<controller type='pci' index='0' model='pcie-root'/>
    		<controller type='pci' index='1' model='pcie-root-port'>
    			<model name='pcie-root-port'/>
    			<target chassis='1' port='0x10'/>
    			<address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0' multifunction='on'/>
    		</controller>
    		<controller type='pci' index='2' model='pcie-root-port'>
    			<model name='pcie-root-port'/>
    			<target chassis='2' port='0x11'/>
    			<address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x1'/>
    		</controller>
    		<controller type='pci' index='3' model='pcie-root-port'>
    			<model name='pcie-root-port'/>
    			<target chassis='3' port='0x12'/>
    			<address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x2'/>
    		</controller>
    		<controller type='pci' index='4' model='pcie-root-port'>
    			<model name='pcie-root-port'/>
    			<target chassis='4' port='0x13'/>
    			<address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x3'/>
    		</controller>
    		<controller type='pci' index='5' model='pcie-root-port'>
    			<model name='pcie-root-port'/>
    			<target chassis='5' port='0x14'/>
    			<address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x4'/>
    		</controller>
    		<controller type='pci' index='6' model='pcie-root-port'>
    			<model name='pcie-root-port'/>
    			<target chassis='6' port='0x15'/>
    			<address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x5'/>
    		</controller>
    		<controller type='pci' index='7' model='pcie-root-port'>
    			<model name='pcie-root-port'/>
    			<target chassis='7' port='0x16'/>
    			<address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x6'/>
    		</controller>
    		<controller type='pci' index='8' model='pcie-root-port'>
    			<model name='pcie-root-port'/>
    			<target chassis='8' port='0x17'/>
    			<address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x7'/>
    		</controller>
    		<controller type='pci' index='9' model='pcie-root-port'>
    			<model name='pcie-root-port'/>
    			<target chassis='9' port='0x18'/>
    			<address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0' multifunction='on'/>
    		</controller>
    		<controller type='pci' index='10' model='pcie-root-port'>
    			<model name='pcie-root-port'/>
    			<target chassis='10' port='0x19'/>
    			<address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x1'/>
    		</controller>
    		<controller type='pci' index='11' model='pcie-root-port'>
    			<model name='pcie-root-port'/>
    			<target chassis='11' port='0x1a'/>
    			<address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x2'/>
    		</controller>
    		<controller type='pci' index='12' model='pcie-root-port'>
    			<model name='pcie-root-port'/>
    			<target chassis='12' port='0x1b'/>
    			<address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x3'/>
    		</controller>
    		<controller type='pci' index='13' model='pcie-root-port'>
    			<model name='pcie-root-port'/>
    			<target chassis='13' port='0x1c'/>
    			<address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x4'/>
    		</controller>
    		<controller type='pci' index='14' model='pcie-root-port'>
    			<model name='pcie-root-port'/>
    			<target chassis='14' port='0x1d'/>
    			<address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x5'/>
    		</controller>
    		<controller type='pci' index='15' model='pcie-root-port'>
    			<model name='pcie-root-port'/>
    			<target chassis='15' port='0x1e'/>
    			<address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x6'/>
    		</controller>
    		<controller type='pci' index='16' model='pcie-to-pci-bridge'>
    			<model name='pcie-pci-bridge'/>
    			<address type='pci' domain='0x0000' bus='0x08' slot='0x00' function='0x0'/>
    		</controller>
    		<controller type='sata' index='0'>
    			<address type='pci' domain='0x0000' bus='0x00' slot='0x1f' function='0x2'/>
    		</controller>
    		<controller type='virtio-serial' index='0'>
    			<address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x0'/>
    		</controller>
    		<filesystem type='mount' accessmode='passthrough'>
    			<driver type='virtiofs'/>
    			<source dir='/home/dtgagnon/myVMs/vm_share'/>
    			<target dir='nix_share'/>
    			<address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>
    		</filesystem>
    		<interface type='network'>
    			<mac address='52:54:00:68:e5:87'/>
    			<source network='default'/>
    			<model type='virtio'/>
    			<address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
    		</interface>
    		<serial type='pty'>
    			<target type='isa-serial' port='0'>
    				<model name='isa-serial'/>
    			</target>
    		</serial>
    		<console type='pty'>
    			<target type='serial' port='0'/>
    		</console>
    		<channel type='spicevmc'>
    			<target type='virtio' name='com.redhat.spice.0'/>
    			<address type='virtio-serial' controller='0' bus='0' port='1'/>
    		</channel>
    		<input type='mouse' bus='virtio'>
    			<address type='pci' domain='0x0000' bus='0x0a' slot='0x00' function='0x0'/>
    		</input>
    		<input type='keyboard' bus='virtio'>
    			<address type='pci' domain='0x0000' bus='0x09' slot='0x00' function='0x0'/>
    		</input>
    		<input type='mouse' bus='ps2'/>
    		<input type='keyboard' bus='ps2'/>
    		<tpm model='tpm-crb'>
    			<backend type='emulator' version='2.0'>
    				<profile name='default-v1'/>
    			</backend>
    		</tpm>
    		<graphics type='spice' port='-1' autoport='no'>
    			<listen type='address'/>
    			<image compression='off'/>
    		</graphics>
    		<sound model='ich9'>
    			<audio id='1'/>
    			<address type='pci' domain='0x0000' bus='0x00' slot='0x1b' function='0x0'/>
    		</sound>
    		<audio id='1' type='spice'/>
    		<video>
    			<model type='vga' vram='16384' heads='1' primary='yes'/>
    			<address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x0'/>
    		</video>
    		<hostdev mode='subsystem' type='pci' managed='yes'>
    			<source>
    				<address domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
    			</source>
    			<rom bar='on'/>
    			<address type='pci' domain='0x0000' bus='0x06' slot='0x00' function='0x0'/>
    		</hostdev>
    		<hostdev mode='subsystem' type='pci' managed='yes'>
    			<source>
    				<address domain='0x0000' bus='0x01' slot='0x00' function='0x1'/>
    			</source>
    			<rom bar='on'/>
    			<address type='pci' domain='0x0000' bus='0x07' slot='0x00' function='0x0'/>
    		</hostdev>
    		<hostdev mode='subsystem' type='usb' managed='yes'>
    			<source>
    				<vendor id='0x256f'/>
    				<product id='0xc635'/>
    			</source>
    			<address type='usb' bus='0' port='1'/>
    		</hostdev>
    		<!-- elgato camlink 4k -->
    		<!-- <hostdev mode='subsystem' type='usb' managed='yes'>
    			<source>
    				<vendor id='0x2207'/>
    				<product id='0x110c'/>
    			</source>
    			<address type='usb' bus='0' port='5'/>
    		</hostdev> -->
    		<redirdev bus='usb' type='spicevmc'>
    			<address type='usb' bus='0' port='2'/>
    		</redirdev>
    		<redirdev bus='usb' type='spicevmc'>
    			<address type='usb' bus='0' port='3'/>
    		</redirdev>
    		<watchdog model='itco' action='reset'/>
    		<memballoon model='none'/>
    	</devices>
    	<qemu:commandline>
    		<qemu:arg value='-device'/>
    		<qemu:arg value='{&quot;driver&quot;:&quot;ivshmem-plain&quot;,&quot;id&quot;:&quot;shmem0&quot;,&quot;memdev&quot;:&quot;looking-glass&quot;}'/>
    		<qemu:arg value='-object'/>
    		<qemu:arg value='{&quot;qom-type&quot;:&quot;memory-backend-file&quot;,&quot;id&quot;:&quot;looking-glass&quot;,&quot;mem-path&quot;:&quot;/dev/kvmfr0&quot;,&quot;size&quot;:67108864,&quot;share&quot;:true}'/>
    		<qemu:arg value='-fw_cfg'/>
    		<qemu:arg value='opt/ovmf/X-PciMmio64Mb,string=65536'/>
    	</qemu:commandline>
    </domain>
''
